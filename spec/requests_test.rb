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
      end

      it "should be able to handle multiple TCP connections" do
        threads = []
        10.times do
          threads << Thread.new do
            s = TCPSocket.open("localhost", PORT)
            sleep 1
            expect(s.closed?).to eq(false)
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
      end
    end

   after(:context) do
     # Kill the server after every context.
     Process.kill "INT", @server_pid
   end
end
