require_relative '../lib/em-xs'

#endpoint = "ipc://test-push-pull-#{rand(1000)}.ipc"
endpoint = "inproc://test-push-pull-#{rand(1000)}"
#endpoint = "tcp://127.0.0.1:9999"

pull = EM::XS::Socket.create :pull, :bind, endpoint
push = EM::XS::Socket.create :push, :connect, endpoint

class Handler
  def on_recv(msg)
    puts msg.inspect
  end
end

trap 'INT' do
  EM.stop if EM.reactor_running?
end

EM.run do
  pull.em_watch Handler.new
  EM.add_periodic_timer(0.1) { push.send_msg('Hello World') }
end

pull.close
push.close
