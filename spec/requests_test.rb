#!/snap/bin/ruby
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
PORT = 4200

describe "Request Tests" do

    before(:context) do
      # Create a new server on localhost:PORT (for every context)
      @server_pid = fork do
        output = `#{__dir__}/../lib/easel.rb #{PATH_TO_YAML}`
        puts output
      end
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
        lines = []
        line = s.gets
        until line.nil?
          lines << line
          line = s.gets
        end
        expect(lines[0]).to eq("HTTP/1.1 200 OK\r\n")
        s.close
      end

      it "should be able to appropriately handle a HEAD request" do
        s = TCPSocket.open("localhost", PORT)
        s.write "HEAD /createComponents.js HTTP/1.1\r\n" +
                "Accept: text/javascript\r\n" +
                "Accept-Language: en-gb;q=0.8, en;q=0.7\r\n" +
                "\r\n\r\n"
        lines = []
        line = s.gets
        until line.nil?
          lines << line
          line = s.gets
        end
        expect(lines[0]).to eq("HTTP/1.1 200 OK\r\n")
        s.close
      end

      it "should be able to handle requests with difficult fields." do
        s = TCPSocket.open("localhost", PORT)
        s.write "GET /createComponents.js HTTP/1.1\r\n" +
                "Accept: text/javascript\r\n" +
                "UglyField: bad:bad:bad:value" +
                "\r\n\r\n"
        lines = []
        line = s.gets
        until line.nil?
          lines << line
          line = s.gets
        end
        expect(lines[0]).to eq("HTTP/1.1 200 OK\r\n")
        s.close
      end
    end


    context "The WebSocket Server" do

      it "should accept websocket upgrades properly" do
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

        line = s.gets
        while line != "\r\n"
          line = s.gets
        end

        s.close
      end

      it "should be able to respond to 0:RUN within 500ms" do

        fp = File.new("/home/epwr/projects/easel/out.txt", "w")
        s = TCPSocket.open("localhost", PORT)
        s.write "GET / HTTP/1.1\r\n" +
                "Upgrade: websocket\r\n" +
                "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==\r\n" +
                "\r\n"
        fp.puts "here11111"
        loop do
          begin
            line = s.gets
          rescue Exception => e
            fp.puts "Error: #{e}"
            sleep 2
            line = "garbage"
          end
          puts "LINE: '#{line}'"
          raise "No Sec-WebSocket-Accept field returned" if line.nil?
          break if line.include? "Sec-WebSocket-Accept: "
        end
        fp.puts "here2"
        expect(line.split(": ")[1]).to eq("HSmrc0sMlYUkAGmm5OPpG2HaGWk=\r\n")


        fp.puts "hello"

        line = s.gets
        while line != "\r\n"
          line = s.gets
        end

        Timeout::timeout(0.5) do
          msg = "0:RUN"

          fp.puts "0b10000000"
          fp.puts "#{msg.size.to_s(2)}"
          fp.puts "#{(0b10000000 | msg.size).to_s(2)}"
          output = [0b10000001, (0b10000000 | msg.size), msg]
          fp.puts output.pack("CCA#{msg.size}")
          s.write output.pack("CCA#{msg.size}")
          loop {
            line =  s.gets
            p line
            break if line.nil?
          }
        end

      end

      it "should stream the first DID command with 500ms of accepting the upgrade." do
        fail
      end

    end

   after(:context) do
     # Kill the server after every context.
     Process.kill "INT", @server_pid
   end
end
