#!/snap/bin/ruby
#
# Author: Eric Power
#
# Description:
#     Provides the server that serves Cdash.

# Imports
require 'socket'
require_relative './build_pages.rb'


def launch_server

  # Lauch the TCPServer
  begin
    server = TCPServer.new($config[:hostname], $config[:port])
  rescue Exception => e
    log_fatal "Server could not start. Error message: #{e}"
  end

  Thread.abort_on_exception = true

  # Main Loop
  begin
    loop {                           # Servers run forever
    Thread.start(server.accept) do |client|
      handle_request client
    end
  }

  # Handle shutting down.
  rescue Interrupt
    log_info "Interrupt received, server shutting down..."
    children.each { |child| child.exit }
  end
end


def handle_request socket

  log_info "Receieved request: #{socket}"
  message = socket.eat_buffer

  response = build_app

  # We need to include the Content-Type and Content-Length headers
  # to let the client know the size and type of data
  # contained in the response. Note that HTTP is whitespace
  # sensitive, and expects each header line to end with CRLF (i.e. "\r\n")
  socket.print "HTTP/1.1 200 OK\r\n" +
               "Content-Type: text/plain\r\n" +
               "Content-Length: #{response.bytesize}\r\n" +
               "Connection: close\r\n"

  # Print a blank line to separate the header from the response body,
  # as required by the protocol.
  socket.print "\r\n"

  # Print the actual response body, which is just "Hello World!\n"
  socket.print response

  # Close the socket, terminating the connection
  socket.close
end


# Monkey patch in a nice eat_buffer method.
class TCPSocket

  def eat_buffer
    contents = ''
    buffer = ''
    begin
    loop {
      recv_nonblock(256, 0, buffer)
      contents += buffer
    }
    rescue IO::EAGAINWaitReadable
      contents
    end
  end

end
