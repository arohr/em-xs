# em-xs

Thin wrapper around crossroads I/O (XS) socket (via ffi-rxs ruby binding) which can be used in combination with EventMachine.
It provides a simple API which is more "ruby like" than the plain ffi-rxs binding.


# Usage

```ruby
require 'em-xs'

# Define the endpoint for the two sockets
endpoint = 'ipc://push-pull-test.ipc'

# Create a PULL socket and bind it
pull = EM::XS::Socket.create :pull, :bind, endpoint

# Create a PUSH socket and connect it
push = EM::XS::Socket.create :push, :connect, endpoint

# Setup INT handler to teardown the application properly
run = true
trap 'INT' do
  run = false
end

# The "mainloop": send and receive messages
while run
  # Send a message via the PUSH socket
  push.send_msg 'Hello World'

  # Revceive a message an handle it in the code block
  pull.recv_msg { |msg| puts msg.inspect }

  # Wait a little
  sleep 0.1
end

# Close sockets properly
pull.close
push.close
```


For more examples see `examples` directory.


## Creating and Configuring sockets

To create sockets the factory `EM::XS::Socket.create` must be used:

    EM::XS::Socket.create(type, bind_or_connect, endpoint, context = nil, sockopts = {}, &block)

It takes arguments for the socket type, the bind or connect operation and a endpoint. If no context is given,
a singleton context object is created automatically (`Context.instance.xs_context`) for you, but you can also pass
a own context instance if you need to.

The socket factory also takes a hash and/or a block configure the socket (calls setsockopt internally):

```ruby
# Create e PUB socket, set SNDHWM to 100 and bind it
pub = EM::XS::Socket.create :pub, :bind, endpoint, nil, {:sndhwm => 100}

# Create s SUB socket, setup a subscription 'my_topic' and connect it
sub = EM::XS::Socket.create :sub, :connect, endpoint do |sock|
  sock.subscribe 'my_topic'
end
```


## Usage in combination with `EventMachine`

Via `Socket#em_watch` a socket can be registered to a `EventMachine` event loop. EM then takes
care of the event handling and calls #on_recv(msg) on the configured handler object.

```ruby
require 'em-xs'

# Create the sockets
endpoint = 'inproc://test-push-pull'
pull = EM::XS::Socket.create :pull, :bind, endpoint
push = EM::XS::Socket.create :push, :connect, endpoint

# A handler class which must implement #on_recv.
class Handler
  def on_recv(msg)
    puts msg.inspect
  end
end

# Setup INT handler to teardown the application properly
trap 'INT' do
  EM.stop if EM.reactor_running?
end

# Run the EM event loop
EM.run do
  # Register the PULL socket for incoming message events
  pull.em_watch Handler.new

  # Periodically send some message via the PUSH socket
  EM.add_periodic_timer(0.1) { push.send_msg('Hello World') }
end

# Close sockets properly
pull.close
push.close
```

# Prerequisites

You need:

    gem install ffi-rxs eventmachine


I tested with MRI 1.9.3, but should work on Rubinius and JRuby too.


## Build and install gem

    git clone git://github.com/arohr/em-xs.git
    rake build
    rake install




# TODO

* More specs.
* Maybe renaming, because there exists already an lib called em-xs (https://github.com/schmurfy/em-xs)
which is similar but has a different API.

