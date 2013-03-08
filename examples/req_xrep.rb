require_relative '../lib/em-xs'

endpoint = "ipc://test-req-xrep-#{rand(1000)}.ipc"

class Handler
  def initialize(sock)
    @sock = sock
  end

  def on_recv(msg)
    puts "request: #{msg.inspect}"
    @sock.send_msg [msg.first, '', 'hello universe']
  end
end


fork do
  xrep = EM::XS::Socket.create(:xrep, :bind, endpoint, nil, :identity => 'server')

  EM.run do
    xrep.em_watch Handler.new(xrep)
  end

  xrep.close
end



req = EM::XS::Socket.create :req, :connect, endpoint, nil, :identity => 'client'

loop do
  req.send_msg "hello world"
  #req.sock.recv_string str = ''
  #puts str.inspect
  #sleep 1
  puts "response: #{req.recv_msg_blocking.inspect}"

  sleep 1
end