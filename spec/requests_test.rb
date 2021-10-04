#!/snap/bin/ruby
#
# Author: Eric Power
#
# Description:
#     Tests that requests from a client (eg. a web browser) work properly.

# Imports
require_relative '../lib/easel.rb'
require 'open3'

# Key Variables
PATH_TO_YAML = "#{__FILE__}/../docs/examples/dash-1.yaml"

describe RequestTests do


    before(:context) do
      # Create a new server on localhost:4211 (for every context)
      @saved_ARGV = ARGV
      ARGV = [PATH_TO_YAML]
      @server_pid = fork do
        launch
      end
      puts "FOUND PID: #{@server_pid}" # TODO: make sure this holds the actual pid.
    end

   context "The TCP Server" do

      it "should accept TCP connections" do

      end

      it "should close TCP connections after a non-HTTP formated string is sent." do
         msg "this is not HTTP - idk what this is."
         # TODO:
      end

      it "should be able to handle multiple TCP connections" do

        10.times do
          fork do
            # TODO: connect to server
            sleep 1
            # TODO: ensure that connection is still open. Maybe send a GET.
          end
        end
      end

   end




   after(:context) do
     # Kill the server after every context.
     # TODO: Kill the server using @server_pid
   end
end
