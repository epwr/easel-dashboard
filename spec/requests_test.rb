#!/snap/bin/ruby
#
# Author: Eric Power
#
# Description:
#     Tests that requests from a client (eg. a web browser) work properly.

# Imports
require_relative '../lib/easel.rb'
require 'socket'

# Key Variables
PATH_TO_YAML = "#{__dir__}/../docs/examples/dash-1.yaml"

describe "Request Tests" do


    before(:context) do
      # Create a new server on localhost:4211 (for every context)
      @saved_ARGV = ARGV
      ARGV = ["-p", "4211", PATH_TO_YAML]
      @server_pid = fork do
        launch
      end
      sleep 120 # Allow the server to set up.
      puts "FOUND PID: #{@server_pid}" # TODO: make sure this holds the actual pid.
    end

   context "The TCP Server" do

      it "should accept TCP connections" do
        s = TCPSocket.open("localhost", 4211)
        expect(s.closed?).to eq(false)
      end

      it "should close TCP connections after a non-HTTP formated string is sent." do
         msg "this is not HTTP - idk what this is."
         s = TCPSocket.open("localhost", 4211)
         s.send msg
         expect(s.closed?).to eq(true)
      end

      it "should be able to handle multiple TCP connections" do
        threads = []
        10.times do
          threads << Thread.new do
            s = TCPSocket.open("localhost", 4211)
            sleep 1
            expect(s.closed?).to eq(false)
          end
        end
        threads.each { |thr| thr.join }
      end
   end

   after(:context) do
     # Kill the server after every context.
     Process.kill "INT", @server_pid
     ARGV = @saved_ARGV
   end
end
