#!/snap/bin/ruby
#
# Author: Eric Power
#
# Description:
#     Contains the functions that control the websocket. The WebSocket protocol
#     that I'm implementing/creating has a max frame size of MAX_WS_FRAME_SIZE
#     bytes.
#
#     Incoming frames are either RUN:XXXXXXXXX or STOP:XXXXXXXXX where XXXXXXXXX
#     is the command's name. Outgoing frames contain a message of the form
#     ID:XXXXXXXXX where XXXXXXXXX is output given to the frame called ID.
#
# Note: Websocket code is based on the code provided in the following article:
# https://www.honeybadger.io/blog/building-a-simple-websockets-server-from-scratch-in-ruby/

# Imports
require 'digest'

# Key Variables
MAX_WS_FRAME_SIZE = 50.0

# run_websocket
#
#
def run_websocket(socket, initial_request)

  accept_connection( socket, initial_request[:fields][:Sec_WebSocket_Key][0..-3])

  loop {
    msg = receive_msg socket
    break if msg.nil?

    case msg.split(":")[0]
    when "RUN"
      cmd_name = msg.match(/^RUN:(.*)$/)[1]
      cmd = get_command cmd_name
      cmd_output = `#{cmd}`
      send_msg(socket, cmd_output)
    when "STOP"

    else
      log_error "Received an unrecognized message over the websocket: #{msg}"
    end
  }

end


# get_command
#
#
def get_command cmd_name
  $config[:commands].each { |cmd|
    return cmd[:cmd] if cmd[:name] == cmd_name
  }
end

# accept_connection
#
# Sends back the HTTP header to initialize the websocket connection.
def accept_connection(socket, ws_key)

  ws_accept_key = Digest::SHA1.base64digest(
    ws_key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
  socket.write "HTTP/1.1 101 Switching Protocols\r\n" +
               "Upgrade: websocket\r\n" +
               "Connection: Upgrade\r\n" +
               "Sec-WebSocket-Accept: #{ws_accept_key}\r\n" +
               "\r\n"
end


# receive_msg
#
#
def receive_msg socket

  # Check first two bytes
  byte1 = socket.getbyte
  byte2 = socket.getbyte
  if byte1 == 0x88  # Browser is requesting that we close the connection.
    socket.close
    return
  end
  fin = byte1 & 0b10000000
  opcode = byte1 & 0b00001111
  msg_size = byte2 & 0b01111111
  is_masked = byte2 & 0b10000000
  unless fin and opcode == 1 and is_masked and msg_size < MAX_WS_FRAME_SIZE
    log_error "Invalid websocket message received. #{byte1}-#{byte2}"
    puts socket.gets
    msg_size.times.map { socket.getbyte }  # Read message from socket.
    return
  end

  # Get message
  mask = 4.times.map { socket.getbyte }
  msg = msg_size.times.map { socket.getbyte }.each_with_index.map {
    |byte, i| byte ^ mask[i % 4]
  }.pack('C*').force_encoding('utf-8').inspect
  msg[1..-2] # Remove quotation marks from message

end


# send_msg
#
#
def send_msg(socket, msg)

  # Set a max frame size of MAX_WS_FRAME_SIZE bytes.
  def send_frame(socket, fmsg)

    output = [0b10000001, fmsg.size, fmsg]
    socket.write output.pack("CCA#{fmsg.size}")

  end

  if msg.size < MAX_WS_FRAME_SIZE
    send_frame(socket, msg)
  else
    (0..(msg.size/MAX_WS_FRAME_SIZE).ceil - 1).each { |num|
      send_frame(socket, msg[num*MAX_WS_FRAME_SIZE..(num+1)*MAX_WS_FRAME_SIZE - 1])
    }
  end
end
