require_relative '../lib/em-xs'

#endpoint = "ipc://test-push-pull-#{rand(1000)}.ipc"
endpoint = "ipc://test-pub-sub-#{rand(1000)}"
#endpoint = "tcp://127.0.0.1:9999"

pub = EM::XS::Socket.create :pub, :bind, endpoint
sub = EM::XS::Socket.create :sub, :connect, endpoint
sub.subscribe ''

class Handler
  def on_recv(msg)
    puts msg.inspect
  end
end

trap 'INT' do
  EM.stop if EM.reactor_running?
end

EM.run do
  sub.em_watch Handler.new
  EM.add_periodic_timer(0.1) { pub.send_msg('Hello World') }
end

pub.close
sub.close






