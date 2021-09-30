#!/snap/bin/ruby
#
# Author: Eric Power
#
# Description:
#     Provides the server that serves Easel Dashboard.

# Imports
require 'socket'
require_relative './build_pages'
require_relative './websocket'
require_relative './data_gathering'


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

  # Main Loop
  begin
    loop {
      Thread.start(server.accept) do |client|
        handle_request client
    end
  }

  # Handle shutting down.
  rescue Interrupt
    log_info "Interrupt received, server shutting down..."
  end
end


def handle_request socket

  log_info "Receieved request: #{socket}"
  request = read_HTTP_message socket

  # TODO: check what the minimum allow handling is. I think there's one more method I need to handle.
  case request[:method]
  when "GET"
    # TODO: respond with app, css file, favicon, or 404 error.
    if request[:fields][:Upgrade] == "websocket\r\n"
      run_websocket(socket, request)
    else
        handle_get(socket, request)
    end
  #when "HEAD"
    # TODO: Deal with HEAD request. https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.4
  else
    # TODO: respond with an appropriate error.
    socket.print "HTTP/1.1 200 OK\r\n" +
                 "Content-Type: text/plain\r\n" +
                 "Content-Length: #{response.bytesize}\r\n" +
                 "Connection: close\r\n" +
                 "\r\n" +
                 response
    socket.close
  end

end



# handle_get
#
# Handle a get request.
def handle_get(socket, request)

  case request[:url]
  when "/", "/index.html"
    socket.print build_app
    socket.close
  when "/test.html" # TODO: Remove this!
    socket.print return_html "test.html"
    socket.close
  when "/app.css"
    socket.print build_css
    socket.close
  when "/controller.js"
    log_info "building controller"
    socket.print build_js
    socket.close
  when "/dashboardElements.js"
    socket.print return_js 'dashboardElements.js'
    socket.close
  when "/createComponents.js"
    socket.print return_js 'createComponents.js'
    socket.close
  else
    socket.print build_error 404
    socket.close
  end

end


# read_HTTP_message
#
# Read an HTTP message from the socket, and parse it into a request Hash.
def read_HTTP_message socket
  message = []
  loop do
    line = socket.gets
    message << line
    if line == "\r\n"
      break
    end
  end

  request = {fields: {}}
  (request[:method], request[:url], request[:protocol]) = message[0].split(" ")

  message[1..-1].each{ |line|
    (key, value) = line.split(": ")
    request[:fields][key.split("-").join("_").to_sym] = value
  }
  request
end
