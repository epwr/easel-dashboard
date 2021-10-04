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

describe "Request Tests" do

    before(:context) do
      # Create a new server on localhost:4200 (for every context)
      @server_pid = fork do
        output = `#{__dir__}/../lib/easel.rb #{PATH_TO_YAML}`
        puts "SERVER LOGS:\n#{output}"
      end
      sleep 1 # Allow the server to set up.
    end

   context "The TCP Server" do

      it "should accept TCP connections" do
        s = TCPSocket.open("localhost", 4200)
        expect(s.closed?).to eq(false)
      end

      it "should be able to handle multiple TCP connections" do
        threads = []
        10.times do
          threads << Thread.new do
            s = TCPSocket.open("localhost", 4200)
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
   end
end
