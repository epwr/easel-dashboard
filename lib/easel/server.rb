#!/bin/env ruby
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
  rescue Interrupt # Handle shutting down.
    log_info "Interrupt received, server shutting down..."
  rescue Exception => e
    log_error "Unexpected error occured and closed client connection. Error: #{e}"
    e.backtrace.each { |trace| log_error "#{trace}" }
  end
end


def handle_request socket

  log_info "Receieved request: #{socket}"
  request = read_HTTP_message socket

  if request.nil?
    socket.print build_error 400
    socket.close
    return
  end

  case request[:method]
  when "GET"
    if request[:fields][:Upgrade] == "websocket\r\n"
      run_websocket(socket, request)
    else
        handle_get(socket, request)
    end
  when "HEAD"
    if request[:fields][:Upgrade] == "websocket\r\n"
    else
      read_end, write_end = IO.pipe
      handle_get(write_end, request)
      msg = ""
      loop do
        msg += read_end.readline
        if msg.include? "\r\n\r\n"
          socket.print msg
          socket.close
          break
        elsif read_end.readline.nil?
          socket.print build_error 500
          socket.close
          break
        end
      end
    end
  else
    puts "THIS SHOULD NOT OCCUREEEEEE"
    socket.print build_error 400
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
    socket.close unless request[:Connection].is_a? String and request[:Connection].downcase == "keep-alive\r\n"
  when "/app.css"
    socket.print build_css
    socket.close unless request[:Connection].is_a? String and request[:Connection].downcase == "keep-alive\r\n"
  when "/controller.js"
    log_info "building controller"
    socket.print build_js
    socket.close unless request[:Connection].is_a? String and request[:Connection].downcase == "keep-alive\r\n"
  when "/dashboardElements.js"
    socket.print return_js 'dashboardElements.js'
    socket.close unless request[:Connection].is_a? String and request[:Connection].downcase == "keep-alive\r\n"
  when "/createComponents.js"
    socket.print return_js 'createComponents.js'
    socket.close unless request[:Connection].is_a? String and request[:Connection].downcase == "keep-alive\r\n"
  # TODO: respond with favicon
  else
    socket.print build_error 404
    socket.close unless request[:Connection].is_a? String and request[:Connection].downcase == "keep-alive\r\n"
  end

  log_info "Handled HTTP request: #{request}"

end


# read_HTTP_message
#
# Read an HTTP message from the socket, and parse it into a request Hash.
def read_HTTP_message socket
  message = []
  first_line = true
  loop do
    line = socket.gets
    if first_line
      return nil if line.nil? or not line.match(/^(GET|HEAD|POST|PUT|DELETE|OPTIONS|TRACE) .+ HTTP.+/)
      first_line = false
    end
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
