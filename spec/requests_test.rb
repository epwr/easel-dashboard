#!/bin/env ruby
#
# Author: Eric Power
#
# Description:
#     Tests that requests from a client (eg. a web browser) work properly.

# Imports
require 'socket'
require 'timeout'

# Key Variables
PATH_TO_YAML = "#{__dir__}/../docs/examples/dash-1.yaml"
PATH_TO_LOG = "docs/testing/testing.log"
PORT = 4200

describe "Request Tests" do

    before(:all) do
      # Empty out the log file
      fp = File.new(PATH_TO_LOG, "w")
      fp.close
    end

    before(:context) do
      # Create a new server on localhost:PORT (for every context)
      @saved_ARGV = ARGV
      @saved_VERBOSE = $VERBOSE
      @server = Thread.new{
        $VERBOSE = nil
        ARGV = [ "-o", "#{PATH_TO_LOG}", "-l", "3", "#{PATH_TO_YAML}"]
        $VERBOSE = @saved_VERBOSE
        require_relative '../lib/easel.rb'
        launch

        # output = `#{__dir__}/../lib/easel.rb -o #{__dir__}/../docs/testing/testing.log -l 3 #{PATH_TO_YAML}`
      }
      sleep 1 # Allow the server to set up.
    end

    context "The TCP Server" do
      it "should accept TCP connections" do
        s = TCPSocket.open("localhost", PORT)
        expect(s.closed?).to eq(false)
        s.close
      end

      it "should be able to handle multiple TCP connections" do
        threads = []
        10.times do
          threads << Thread.new do
            s = TCPSocket.open("localhost", PORT)
            sleep 1
            expect(s.closed?).to eq(false)
            s.close
          end
        end
        threads.each { |thr| thr.join }
      end
    end


    context "The HTTP Server" do

      it "should handle a properly formed GET request" do
        s = TCPSocket.open("localhost", PORT)
        s.write "GET /createComponents.js HTTP/1.1\r\n" +
                "Accept: text/javascript\r\n" +
                "Accept-Language: en-gb;q=0.8, en;q=0.7\r\n" +
                "\r\n\r\n"
        line = s.gets
        expect(line).to eq("HTTP/1.1 200 OK\r\n")
        s.close
      end

      it "should be able to appropriately handle a HEAD request" do
        s = TCPSocket.open("localhost", PORT)
        s.write "HEAD /createComponents.js HTTP/1.1\r\n" +
                "Accept: text/javascript\r\n" +
                "Accept-Language: en-gb;q=0.8, en;q=0.7\r\n" +
                "\r\n\r\n"
        line = s.gets
        expect(line).to eq("HTTP/1.1 200 OK\r\n")
        s.close
      end

      it "should be able to handle requests with difficult fields." do
        s = TCPSocket.open("localhost", PORT)
        s.write "GET /createComponents.js HTTP/1.1\r\n" +
                "Accept: text/javascript\r\n" +
                "UglyField: bad:bad:bad:value" +
                "\r\n\r\n"
        line = s.gets
        expect(line).to eq("HTTP/1.1 200 OK\r\n")
        s.close
      end

      # it "should keep tcp open when sent HTTP messages with appropriate header fields" do

      # it "should close tcp when sent HTTP messages with appropriate header fields" do


    end


    context "The WebSocket Server" do

      it "should accept websocket upgrades properly" do
        s = TCPSocket.open("localhost", PORT)
        s.write "GET / HTTP/1.1\r\n" +
                "Upgrade: websocket\r\n" +
                "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==\r\n" +
                "\r\n"
        line = s.gets
         # expect(line).to eq("HTTP/1.1 101 Switching Protocols\r\n")
        loop do
          line = s.gets
          raise "No Sec-WebSocket-Accept field returned" if line.nil?
          break if line.include? "Sec-WebSocket-Accept: "
        end
        expect(line.split(": ")[1]).to eq("HSmrc0sMlYUkAGmm5OPpG2HaGWk=\r\n")

        line = s.gets
        while line != "\r\n"
          line = s.gets
        end
        s.close
        sleep 0.5 # TCP Server is sending a reset insteand of closing and then reopening unless there's a delay.
      end

      it "should be able to respond to 0:RUN within 500ms" do

        s = TCPSocket.open("localhost", PORT)
        s.write "GET / HTTP/1.1\r\n" +
                "Upgrade: websocket\r\n" +
                "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==\r\n" +
                "\r\n"
        line = ""
        loop do
          line = s.gets
          raise "No Sec-WebSocket-Accept field returned" if line.nil?
          break if line.include? "Sec-WebSocket-Accept: "
        end

        expect(line.split(": ")[1]).to eq("HSmrc0sMlYUkAGmm5OPpG2HaGWk=\r\n")

        lineAA = s.gets
        while lineAA != "\r\n"
          lineAA = s.gets
        end

        Timeout::timeout(0.5) do  # TODO: Change from 5 to 0.5
          msg = "0:RUN"
          mask = 4.times.map{ rand(125) }
          output = [0b10000001, (0b10000000 | msg.size)]
          mask.each { |byte| output << byte }
          msg.bytes.each_with_index { |byte, i|
            output << (byte ^ mask[i % 4])
          }
          s.write output.pack("C6C#{msg.bytes.length}")

          lineBB =  s.gets
        end

        s.close

      end

      # it "should stream the first DID command with 500ms of accepting the upgrade." do
      #   fail
      # end

      # it "should close the websocket properly when requested" do
      # https://datatracker.ietf.org/doc/html/rfc6455#section-1.4

      # it "should require all neccessary fields be present in the Upgrade request"
      # https://datatracker.ietf.org/doc/html/rfc6455#section-4.2.1

      # it "should require valid version of the websocket protocol"
      # https://datatracker.ietf.org/doc/html/rfc6455#section-4.4

      # it "should be able to receive large websocket messages" do
      # https://datatracker.ietf.org/doc/html/rfc6455#section-5.2
      # handle extended payload length (and extended payload length continued)

    end

   after(:context) do
     # Kill the server after every context.
     @server.kill
     $VERBOSE = nil
     ARGV = @saved_ARGV
     $VERBOSE = @saved_VERBOSE
   end
end
