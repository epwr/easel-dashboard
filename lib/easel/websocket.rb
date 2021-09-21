#!/snap/bin/ruby
#
# Author: Eric Power
#
# Description:
#     Contains the functions that control the websocket. The WebSocket protocol
#     that I'm implementing/creating has a max frame size of MAX_WS_FRAME_SIZE
#     bytes.
#
# Note: Websocket code is based on the code provided in the following article:
# https://www.honeybadger.io/blog/building-a-simple-websockets-server-from-scratch-in-ruby/


# Imports
require 'digest'  # Allows hashing of websocket authentication value
require 'open3'   # Allows capturing stdout and stderr of system commands
require 'thread'  # Allows use of mutexes.

require_relative 'data_gathering'

# Key Variables
MAX_WS_FRAME_SIZE = 50.0  # Must be a float number to allow a non-truncated division result.

# run_websocket
#
#
def run_websocket(socket, initial_request)

  accept_connection(socket, initial_request[:fields][:Sec_WebSocket_Key][0..-3])
  child_threads = {}
  send_msg_mutex = Mutex.new # One mutex per websocket to control sending messages.

  Thread.new {  # Periodically update the generic dashboard if set.
    loop do
      puts "---- Getting data! Period: #{$config[:collect_data_period]}"
      data = read_data
      puts "---- Data Read."
      send_msg(socket, send_msg_mutex, nil, "GENDASH", data)
      puts "---- Message sent."
      sleep $config[:collect_data_period]
    end
  } unless $config[:collect_data_period] == 0

  loop {
    msg = receive_msg socket
    break if msg.nil? # The socket was closed by the client.

    case msg.split(":")[0]
    when "RUN"
      cmd_id = msg.match(/^RUN:(.*)$/)[1].to_i

      unless child_threads[cmd_id]
        child_threads[cmd_id] = Thread.new do
          run_command_and_stream(socket, cmd_id, send_msg_mutex)
          child_threads[cmd_id] = nil
        end
      end

    when "STOP"

      cmd_id = msg.match(/^STOP:(.*)$/)[1].to_i
      unless child_threads[cmd_id].nil?
        child_threads[cmd_id].kill
        child_threads[cmd_id] = nil
      end

    else
      log_error "Received an unrecognized message over the websocket: #{msg}"
    end
  }

end


# run_command_and_stream
#
# Run a command and stream the stdout and stderr through the websocket.
def run_command_and_stream(socket, cmd_id, send_msg_mutex)

  cmd = get_command cmd_id
  if cmd.nil?
    log_error "Client requested command ID #{cmd_id} be run, but that ID does not exist."
    return
  end
  Open3::popen3(cmd) do |stdin, stdout, stderr, cmd_thread|

    continue = true

    while ready_fds = IO.select([stdout, stderr])[0]
      ready_fds.each{ |fd|
        resp = fd.gets
        if resp.nil?
          continue = false
          break
        end
        if fd == stdout
          send_msg(socket, send_msg_mutex, cmd_id, "OUT", resp)
        elsif fd == stderr
          send_msg(socket, send_msg_mutex, cmd_id, "ERR", resp)
        else
          raise "Received output from popen3(#{cmd}) that was not via stdout or stderr."
        end
      }
      break unless continue
    end

    cmd_thread.join
    send_msg(socket, send_msg_mutex, cmd_id, "FINISHED")
  end
end



# get_command
#
#
def get_command cmd_id
  $config[:commands].each { |cmd|
    if cmd[:id] == cmd_id
      return cmd[:cmd]
    end
  }
  nil
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
  if byte1 == 0x88  # Client is requesting that we close the connection.
    # TODO: Unsure how to properly handle this case. Right now the socket will close and
    # everything here will shut down - eventually? Kill all child threads first?
    log_info "Client requested the websocket be closed."
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
def send_msg(socket, send_msg_mutex, cmd_id, msg_type, msg=nil)

  # TODO: Figure out the proper frame size (MAX_WS_FRAME_SIZE).
  # TODO: Should this be a private method? I think yes.
  def send_frame(socket, fmsg)
    output = [0b10000001, fmsg.size, fmsg]
    socket.write output.pack("CCA#{fmsg.size}")
  end


  case msg_type
  when "OUT", "ERR"
    header = "#{cmd_id}:#{msg_type}:"
    if header.length > MAX_WS_FRAME_SIZE
      log_error "Message header '#{msg_type}' is too long. Msg: #{msg}."
    elsif msg.nil?
      log_error "Message of type '#{msg_type}' sent without a message."
    else
      send_msg_mutex.synchronize {
        if msg.length > MAX_WS_FRAME_SIZE - header.length
          msg_part_len = MAX_WS_FRAME_SIZE - header.length
          msg_parts = (0..(msg.length-1)/msg_part_len).map{ |i|
            msg[i*msg_part_len,msg_part_len]
          }
          msg_parts.each{ |part|
            send_frame(socket, header + part)
          }
        else
          send_frame(socket, header + msg)
        end
      }
    end

  when "CLEAR", "FINISHED", "GENDASH"
    if !msg.nil?
      log_error "Message of type '#{msg_type}' passed a message. Msg: #{msg}."
    end
    to_send = "#{cmd_id}:#{msg_type}"
    send_msg_mutex.synchronize {
      if to_send.length > MAX_WS_FRAME_SIZE
        log_error "Message of type '#{msg_type}' is too long. Msg: #{to_send}."
      else
        send_frame(socket, to_send)
      end
    }
  else
    log_error "Trying to send a websocket message with unrecognized type: #{msg_type}"
  end

end
