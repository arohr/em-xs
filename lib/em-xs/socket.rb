require 'singleton'

module EM::XS

  # Thin wrapper around XS socket.
  # Aims for providing a simpler API to use XS sockets with (or even without) EventMachine.
  # To attach the socket to a EM eventloop, simply use Socket#em_watch.
  #
  class Socket

    # Global singleton context object for creating XS sockets.
    # This object is threadsafe and should be used to create XS sockets.
    # In order to use inproc transport, all threads MUST use this singleton object to create XS sockets.
    #
    class Context
      include Singleton
      attr_reader :xs_context

      def initialize
        @xs_context = ::XS::Context.create
        #puts "Created context #{@xs_context}\n"
      end

      def terminate
        @xs_context.terminate
      end
    end


    attr_accessor :endpoint
    attr_reader :context

    # Create getters/setters for various socket options.
    #
    %w(sndhwm rcvhwm identity linger).each do |name|
      define_method(name) do
        self.getsockopt name
      end

      define_method("#{name}=") do |value|
        self.setsockopt name, value
      end
    end


    # Returns a string containing the versions of Crossroads-I/O and the FFI ruby binding.
    #
    # @return [String] Versions string
    def self.xs_versions
      "XS version #{::XS::Util.version.join('.')}, ffi-rxs version #{::XS::VERSION}"
    end



    # Factory method to create a socket, set some socket options and connect or bind at the same time.
    #
    # @param [Symbol] type The socket type
    # @param [Symbol] bind_or_connect Symbol :bind or :connect. Determines the socket operation automatically called after the socket is created.
    # @param [Socket::Context] context The context object to use for socket creation. If nil the global socket object will be used.
    # @param [Hash] sockopts Socket options to setup after the socket is created.
    # @param [Proc] block Optional block which can be used to do additional configuration.
    def self.create(type, bind_or_connect, endpoint, context = nil, sockopts = {}, &block)
      fail "bind_or_connect must be :bind or :connect" unless [:bind, :connect].include? bind_or_connect
      sock = self.new type, endpoint, context

      # set the socket options
      sockopts.each do |opt, value|
        sock.setsockopt opt, value
      end

      yield sock if block_given?

      sock.send bind_or_connect
      sock

    rescue
      sock.close if sock
      raise
    end


    # Creates a new socket and configures the socket options.
    # @see #create for parameters
    def initialize(type, endpoint = nil, context = nil)
      @context = context || Context.instance.xs_context
      @sock = @context.socket xs_const(type)
      @endpoint = endpoint

      fail "Creating socket #{type} failed" unless @sock
    end


    # Returns the socket type as a symbol
    #
    # @return [Symbol] Socket type.
    def type
      @sock.name.downcase.to_sym
    end


    # Calls the connect operation on the socket and checks the result.
    #
    # @param [String] endpoint Socket endpoint. E.g. ipc://mysocket.ipc
    def connect(endpoint = @endpoint)
      assert_rc @sock.connect(endpoint)
    end


    # Calls the bind operation on the socket and checks the result for errors.
    #
    # @param [String] endpoint Socket endpoint. E.g. ipc://mysocket.ipc
    def bind(endpoint = @endpoint)
      assert_rc @sock.bind(endpoint)
    end


    # Class the close operation on the socket and checks the result for errors.
    #
    def close
      assert_rc @sock.close
    end


    # Attaches the socket to the EventMachine loop. EventMachine takes care of the callback.
    #
    # @param [Object] handler Handler object which will get callbacks to #on_recv.
    def em_watch(handler = nil)
      @handler = handler
      @conn = EM.watch getsockopt(::XS::FD), EM::XS::Connection, self
    end


    # Returns true if the sockets is readable. This means that the socket has recevied a message ready to process.
    #
    def readable?
      (getsockopt(::XS::EVENTS) & ::XS::POLLIN) == ::XS::POLLIN
    end


    # Returns true if the socket is writable. This means that the socket is ready to deliver messages.
    #
    def writable?
      (getsockopt(::XS::EVENTS) & ::XS::POLLOUT) == ::XS::POLLOUT
    end


    # Returns a socket option and checks the result for errors.
    #
    # @param [Fixnum] name_or_const XS constant or name of XS constant
    def getsockopt(name_or_const)
      const = xs_const name_or_const
      assert_rc @sock.getsockopt(const, list = [])
      list.first
    end


    # Sets a socket option and checks the result for errors.
    #
    # @param [Fixnum] name_or_const XS constant or name of XS constant
    def setsockopt(name_or_const, value)
      const = xs_const name_or_const
      assert_rc @sock.setsockopt(const, value)
    end


    # Sets up a subscription for the socket. This is only meaningfull on SUB sockets.
    #
    # @param [String] prefix Message prefix for the subscription.
    def subscribe(prefix)
      setsockopt :subscribe, prefix
    end


    # Sends a message over the socket. The message can be a string or an array of strings (multipart message).
    # The result of the operation is checked for errors.
    #
    # @param [String, Array<String>] msg Singlepart (String) or multipart (Array of Strings) message.
    def send_msg(msg)
      fail "Socket is not writable" unless writable?

      case msg
        when Array
          assert_rc @sock.send_strings(msg, ::XS::NonBlocking)
        when String
          assert_rc @sock.send_string(msg, ::XS::NonBlocking)
        else
          fail "Cannot send message of class #{msg.class.name}: #{msg.inspect}"
      end
    end


    # The method is called by the XS::Connection object (callback) when a message has arrived on the socket.
    # All messages ready to consume are read until there are no more messages. For every message (can be
    # singlepart or multipart) the configured handler is called (handler object or block).
    #
    # @param [Proc] block A handler block can be passed instead of a handler object.
    def recv_msg(&block)
      return unless readable?

      # In order to get EM::XS::Connection#notify_readable called again by EM,
      # we need to receive strings until #recv_strings fails.
      loop do
        rc = @sock.recv_strings(strings = [], ::XS::NonBlocking)
        break unless ::XS::Util.resultcode_ok? rc

        if block_given?
          yield strings
        elsif @handler
          @handler.on_recv strings
        end
      end
    end


    def recv_msg_blocking
      assert_rc @sock.recv_strings(strings = [])
      strings
    end


  private

    # Returns an XS constant based on a string or symbol.
    #
    # @param [String, Symbol, Fixnum] name_or_const A symbol or string identifing a XS constant or constant value itself.
    # @return [Fixnum] XS constant.
    def xs_const(name_or_const)
      case name_or_const
        when String, Symbol
          ::XS.const_get name_or_const.to_s.upcase
        when Fixnum
          name_or_const
        else
          fail "Invalid type #{name_or_const.class}"
      end
    rescue NameError
      raise "Undefined XS constant 'XS::#{name_or_const}'"
    end


    # Raises an exception if the return code *rc* singnals an error.
    #
    # @param [Fixnum] rc Return code from calls of the ffi-rxs library.
    def assert_rc(rc)
      fail "XS operation failed! Descr [#{::XS::Util.error_string}] Errno [#{::XS::Util.errno}]" unless ::XS::Util.resultcode_ok? rc
    end

  end

end
