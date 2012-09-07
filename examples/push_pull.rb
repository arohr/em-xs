require_relative '../lib/em-xs'

#endpoint = "ipc://test-push-pull-#{rand(1000)}.ipc"
endpoint = "inproc://test-push-pull-#{rand(1000)}"
#endpoint = "tcp://127.0.0.1:9999"

pull = EM::XS::Socket.create :pull, :bind, endpoint do |sock|
  sock.identity = 'my_puller'
end

push = EM::XS::Socket.create :push, :connect, endpoint

@run = true
trap 'INT' do
  @run = false
end

while @run
  push.send_msg 'Hello World'
  pull.recv_msg { |msg| puts msg.inspect }
  sleep 0.1
end

pull.close
push.close
