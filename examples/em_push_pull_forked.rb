require File.expand_path('../lib/em-xs')

endpoint = "ipc://test-push-pull-#{rand(1000)}.ipc"


class Handler
  def initialize
    @count = 0
  end

  def on_recv(msg)
    puts msg.inspect if @count % 100 == 0
    count = msg.first.to_i
    fail "wrong count" unless @count == count-1
    @count = count
  end
end


fork do
  pull = EM::XS::Socket.create :pull, :bind, endpoint

  EM.run do
    pull.em_watch Handler.new
  end

  pull.close
end


fork do
  push = EM::XS::Socket.create :push, :connect, endpoint
  count = 0

  EM.run do
    EM.add_periodic_timer(0.001) do
      push.send_msg [(count += 1).to_s, 'Hello World']
    end
  end

  push.close
end


trap 'INT' do
  EM.stop if EM.reactor_running?
end

Process.waitall


