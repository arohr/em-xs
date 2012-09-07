require "rspec"
require_relative '../lib/em-xs'


describe EM::XS::Socket do

  before :all do
    puts EM::XS::Socket.xs_versions
    @context = ::XS::Context.create
  end


  after :all do
    @context.terminate
    EM::XS::Socket::Context.instance.terminate
  end


  describe EM::XS::Socket::Context do
    it "should be a singleton object" do
      EM::XS::Socket::Context.instance.should equal(EM::XS::Socket::Context.instance)
    end

    it "should be a indepedent instance" do
      EM::XS::Socket::Context.instance.should_not equal(@context)
    end
  end


  describe '#create' do
    it "type 'pub' should be created correcly" do
      sock = EM::XS::Socket.create :pub, :bind, 'ipc://test-pub.ipc',  @context
      sock.endpoint.should == 'ipc://test-pub.ipc'
      sock.instance_variable_get(:@sock).name.should == 'PUB'
      sock.instance_variable_get(:@context).should equal(@context)
      sock.close
    end

    it "type 'sub' should be created correcly" do
      sock = EM::XS::Socket.create :sub, :connect, 'ipc://test-sub.ipc', @context
      sock.endpoint.should == 'ipc://test-sub.ipc'
      sock.instance_variable_get(:@sock).name.should == 'SUB'
      sock.instance_variable_get(:@context).should equal(@context)
      sock.close
    end

    it "type 'push' with global context should be created correcly" do
      sock = EM::XS::Socket.create :push, :connect, 'ipc://test-push.ipc'
      sock.endpoint.should == 'ipc://test-push.ipc'
      sock.instance_variable_get(:@sock).name.should == 'PUSH'
      sock.instance_variable_get(:@context).should equal(EM::XS::Socket::Context.instance.xs_context)
      sock.close
    end

    it "type 'pull' with global context should be created correcly" do
      sock = EM::XS::Socket.create :pull, :bind, 'ipc://test-pull.ipc'
      sock.endpoint.should == 'ipc://test-pull.ipc'
      sock.instance_variable_get(:@sock).name.should == 'PULL'
      sock.instance_variable_get(:@context).should equal(EM::XS::Socket::Context.instance.xs_context)
      sock.close
    end

    it "should throw a exception if an unknown type is given" do
      expect {
        EM::XS::Socket.create :something_wrong_here, :bind, 'ipc://test.ipc'
      }.to raise_error(RuntimeError)
    end

    it "should throw a exception unless bind or connect is given" do
      expect {
        EM::XS::Socket.create :sub, :something_wrong_here, 'ipc://test.ipc'
      }.to raise_error(RuntimeError)
    end

    it "should throw a exception if a invalid endpoint is given" do
      expect {
        EM::XS::Socket.create :pub, :bind, 'bla://ble'
      }.to raise_error(RuntimeError)
    end
  end


  describe 'sending and receiving messages' do

    it "should receive a sent message correctly" do
      endpoint = 'ipc://test-push-pull.ipc'
      pull = EM::XS::Socket.create :pull, :bind, endpoint
      push = EM::XS::Socket.create :push, :connect, endpoint

      push.send_msg 'Hello World'
      sleep 0.1
      pull.recv_msg do |str|
        str.first.should == 'Hello World'
        pull.close
        push.close
      end
    end


    it "should receive a sent message correctly when using in EM" do
      endpoint = "ipc://test-push-pull-#{rand(1000)}.ipc"
      pull = EM::XS::Socket.create :pull, :bind, endpoint
      push = EM::XS::Socket.create :push, :connect, endpoint

      trap 'INT' do
        EM.stop if EM.reactor_running?
      end

      handler = mock 'handler'
      handler.should_receive(:on_recv).with(['Hello World']) { EM.stop }

      EM.run do
        pull.em_watch handler
        EM.next_tick { push.send_msg('Hello World') }
      end

      pull.close
      push.close
    end

  end

end

