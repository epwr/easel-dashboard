#!/bin/env ruby
#
# Author: Eric Power
#
# Description:
#     Contains the functions that run the TCP server and pass new connections to
#     the http_handler function (in http_server.rb).

# Imports
require 'socket'
require_relative './build_pages'
require_relative './http_server'


# launch_server
#
# Launches the Easel Dashboard by running a TCPServer instance which sends every
# new TCP connection to the http_handler (in http_server.rb)
def launch_server

  # Lauch the TCPServer
  begin
    server = TCPServer.new($config[:hostname], $config[:port])
  rescue Exception => e
    log_fatal "Server could not start. Error message: #{e}"
  end

  # Lauch data collection if turned on.
  launch_data_collection unless $config[:collect_data_period] == 0

  Thread.abort_on_exception = true

  # Pass TCP Connections directly to the HTTP handler.
  begin
    loop {
      Thread.start(server.accept) do |client|
        http_handler client
    end
  }

  rescue Interrupt # Handle shutting down.
    log_info "Interrupt received, server shutting down..."
  rescue Exception => e
    log_fatal "Unexpected error occured and closed client connection. Error: #{e}"
  end
end
