#!/snap/bin/ruby
#
# Author: Eric Power

# Imports
require_relative './configuration'


def launch_easel config

  # r_server_data = Ractor.new config do
  #   'this is a message' # TODO: Implement this.
  # end

  tcp_listener = Ractor.new(config) do |config|
    launch_server config
  end

  tcp_listener.take

end
