module EM::XS

  # EM connection used in combination EventMachine::XS::Socket#em_watch.
  class Connection < EM::Connection

    # Create a connection, stores the socket sets up readable notification. .
    #
    # @param [Socket] sock The EM::XS::Socket.
    def initialize(sock)
      @sock = sock
      self.notify_readable = true
    end


    # Callback called by EventMachine when the sockets gets readable.
    def notify_readable
      @sock.recv_msg
    end


    # Callback called by EventMachine when the sockets gets disconnected.
    def unbind
      detach
      @sock.close
    end

  end

end
