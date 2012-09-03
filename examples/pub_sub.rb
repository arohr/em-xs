$LOAD_PATH << File.join(File.dirname(__FILE__), '..')
require 'em-xs'

#endpoint = "ipc://test-pub-sub-#{rand(1000)}.ipc"
endpoint = "inproc://test-pub-sub-#{rand(1000)}"
#endpoint = "tcp://127.0.0.1:9999"

pub = EM::XS::Socket.create :pub, :bind, endpoint do |sock|
  sock.sndhwm = 100
end

sub1 = EM::XS::Socket.create :sub, :connect, endpoint do |sock|
  sock.subscribe 'sub1'
end

sub2 = EM::XS::Socket.create :sub, :connect, endpoint do |sock|
  sock.subscribe 'sub2'
end

sub3 = EM::XS::Socket.create :sub, :connect, endpoint do |sock|
  sock.subscribe 'sub'
end

@run = true
trap 'INT' do
  @run = false
end

while @run
  pub.send_msg ['sub1', 'Hello World sub1']
  pub.send_msg ['sub2', 'Hello World sub2']
  sub1.recv_msg { |msg| puts "sub1: #{msg.inspect}" }
  sub2.recv_msg { |msg| puts "sub2: #{msg.inspect}" }
  sub3.recv_msg { |msg| puts "sub3: #{msg.inspect}" }
  sleep 0.5
  puts ""
end

pub.close
sub1.close
sub2.close
sub3.close
