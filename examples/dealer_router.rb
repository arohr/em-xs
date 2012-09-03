$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'em-xs'

#endpoint = "ipc://test-req-rep-#{rand(1000)}.ipc"
endpoint = "inproc://test-req-rep-#{rand(1000)}"
#endpoint = "tcp://127.0.0.1:9999"


router = EM::XS::Socket.create :router, :bind, endpoint

dealer1 = EM::XS::Socket.create :dealer, :connect, endpoint do |sock|
  sock.identity = 'dealer1'
end

dealer2 = EM::XS::Socket.create :dealer, :connect, endpoint do |sock|
  sock.identity = 'dealer2'
end


@run = true
trap 'INT' do
  @run = false
end

while @run
  dealer1.send_msg 'Hello World from dealer 1'
  dealer2.send_msg 'Hello World from dealer 2'

  router.recv_msg do |msg|
    puts "router > #{msg.inspect}"
    router.send_msg ['dealer1', 'Hello World from router!']
    router.send_msg ['dealer2', 'Hello World from router!']
  end

  dealer1.recv_msg do |msg|
    puts "dealer1 > #{msg.inspect}"
  end

  dealer2.recv_msg do |msg|
    puts "dealer2 > #{msg.inspect}"
  end

  sleep 0.5
end

dealer1.close
dealer2.close
router.close
