#!/bin/env ruby
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
#
# Overview of the websocket protocol:
#     Communication over the websocket is split into two message types:
#
#       1. Command specific messages
#             These messages are sent from either the client or the server, and
#             are associated with a particular command via an ID. This ID is set
#             by the server when building a page.
#
#             The server sends:
#                 - ID:OUT:XXXXXXX where the contents of XXXX is new content in
#                   the stdOUT of the command that's associated with ID.
#                 - ID:ERR:XXXXXXX where the contents of XXXX is new content in
#                   the stdERR of the command that's associated with ID.
#                 - ID:FINISHED tells the client that the command associated with
#                   ID has finished running.
#                 - ID:CLEAR tells the client that the command associated with ID
#                   wants to clear the current output. This is useful when
#                   handling X-term escape sequences (eg. `top` wants a fresh page)
#             The client sends:
#                 - ID:RUN requests that the server start running the command
#                   associated with ID.
#                 - ID:STOP requests that the server stop running the command
#                   associated with ID.
#
#       2. Dashboard Information
#             These messages let the client indicate what information it wants to
#             handle, and let the server send that content to the client either
#             as a blob (if the information is historical) or as a stream (if
#             the information is real time). When the client requests data, it
#             includes a DID. The difference between the DID and an ID that
#             is associated with a command is that the DID contains a letter
#             at the start (eg. A12).
#
#             DIDs are structured as a letter that represents a dashboard, and
#             a number that represents the element on the dashboard.
#
#             The server sends:
#                 - DID:Y:XXXXXXXX sends data that should be connected to the
#                   DID. The Y is either an A (representing "ALL") to say that the
#                   message is a self-contained data point, or a ratio like (1/2)
#                   to say its the first of two messages that when combined form
#                   a data point.
#
#             At this point, the client does not send anything related to DIDs.
#             Options in the future include letting the client request a range of
#             data, but that will likely wait until the data on the server end
#             is moved out of memory an on to disk.



# Imports
require 'digest'  # Allows hashing of websocket authentication value
require 'open3'   # Allows capturing stdout and stderr of system commands
require 'thread'  # Allows use of mutexes.

require_relative 'data_gathering'

# Key Variables
MAX_WS_FRAME_SIZE = 50.0  # Must be a float number to allow a non-truncated division result.
# TODO: change to 127.0


# run_websocket
#
#
def run_websocket(socket, initial_request)

  accept_connection(socket, initial_request[:fields][:Sec_WebSocket_Key][0..-3])
  log_info "Accepted WebSocket Connection"
  child_threads = {}
  send_msg_mutex = Mutex.new # One mutex per websocket to control sending messages.


  Thread.new {  # Periodically update the generic dashboard if set.
    loop do
      #begin
        data = read_data
        send_msg(socket, send_msg_mutex, nil, "DASH", data)
      #rescue Errno::EPIPE
      #  log_info "Pipe closed erorr while sending periodic data to client"
      #  break
      #end
      sleep $config[:collect_data_period]
    end
  } unless $config[:collect_data_period] == 0

  begin
    loop {
      begin
        msg = receive_msg socket
      rescue Errno::ECONNRESET => e
        log_error "Client reset the connection"
        socket.close
        msg = nil
      end
      break if msg.nil? # The socket was closed by the client.

      case msg.split(":")[1]
      when "RUN"
        cmd_id = msg.match(/^(.*):RUN$/)[1].to_i

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
  rescue Exception => e
    log_error "Wuh Woh #2: #{e}"
    e.backtrace.each { |trace| log_error "#{trace}" }
    raise e
  end

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
# Extremely naive websocket server. Requires masking, and a message with a length
# of at most 125. Needs to be updated to conform with RFC 6544
def receive_msg socket

  # Check first two bytes
  byte1 = socket.getbyte
  byte2 = socket.getbyte
  return nil if byte1.nil? or byte2.nil?
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
    log_error "Invalid websocket message received. #{fin}, #{opcode == 1}, #{is_masked}, #{msg_size}"
    msg_size.times { socket.getbyte }  # Read message from socket.
    return
  end

  # Get message
  mask = 4.times.map { socket.getbyte }
  raise "Not Integer: fin       > #{fin      }" if not fin.is_a? Integer
  raise "Not Integer: msg_size  > #{msg_size }" if not msg_size.is_a? Integer
  raise "Not Integer: opcode    > #{opcode   }" if not opcode.is_a? Integer
  raise "Not Integer: is_masked > #{is_masked}" if not is_masked.is_a? Integer
  raise "Not aRRAY: mask      > #{mask     }" if not mask.is_a? Array
  msg = msg_size.times.map { socket.getbyte }.each_with_index.map { |byte, i|
    byte ^ mask[i % 4]
  }.pack('C*').force_encoding('utf-8').inspect

  log_info "WebSocket received: #{msg}"

  msg[1..-2] # Remove quotation marks from message



end


# send_msg
#
#
def send_msg(socket, send_msg_mutex, cmd_id, msg_type, msg=nil)

  case msg_type
  when "OUT", "ERR" # See comments at the top of the file to explain this part of the protocol.
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

  when "DASH"  # See comments at the top of the file to explain this part of the protocol.
    if msg.nil?
      log_error "Message of type '#{msg_type}' sent without a message."
    end
    msg.each_key { |dash_id|
      msg[dash_id].each_key { |ele_index|
        did = "#{dash_id}#{ele_index}"
        send_msg_mutex.synchronize {
          msg[dash_id][ele_index].each_key { |key|
            data_fragment = "#{key}->#{msg[dash_id][ele_index][key]}"
            if data_fragment.length > MAX_WS_FRAME_SIZE - (did.length + 3)
              msg_part_len = MAX_WS_FRAME_SIZE - (did.length + 7) # TODO: Handle case where header is longer than DID:XX/XX:
              msg_parts = (0..(data_fragment.length-1)/msg_part_len).map{ |i|
                data_fragment[i*msg_part_len,msg_part_len]
              }
              msg_parts.each_with_index{ |part, index|
                header = did + ":#{index + 1}/#{msg_parts.length}:"
                if header.length > MAX_WS_FRAME_SIZE
                  log_error "Message header '#{msg_type}' is too long. Data: #{data_fragment}."
                end
                send_frame(socket, header + part)
              }
            else
              send_frame(socket, did + ":A:" + data_fragment)
            end
          }
        }
      }
    }

  when "CLEAR", "FINISHED"
    if !msg.nil?
      log_error "Message of type '#{msg_type}' passed an empty message. Msg: #{msg}."
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

  log_info "Message sent via WebSocket: #{msg}"

end

# send_frame
#
# Sends a message over the websocket. Requires that the message be an appropriate
# length, and have the right format (eg. checks should be done before calling
# this function).
# TODO: Figure out the proper frame size (MAX_WS_FRAME_SIZE).
def send_frame(socket, msg)

  output = [0b10000001, msg.size, msg]
  begin
    socket.write output.pack("CCA#{msg.size}")
  rescue IOError, Errno::EPIPE
    log_error "WebSocket is closed. Msg: #{msg}"
  end
end
