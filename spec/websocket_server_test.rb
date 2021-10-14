#!/bin/env ruby
#
# Author: Eric Power
#
# Description:
#     Behavioural driven unit tests for the websocket_server, and event_handler.
#     Does not mock accepting requests from the client because those are covered
#     in requests_test.rb
#
#     All tests are based on the idea that TCP sockets can be mocked by pipes.

# Imports
require 'timeout'

# Key Variables
$config = {
  logging: 0  # Turn off logging output.
}

describe "WebSocket Server" do

  before(:context) do
    @data_handler = nil # TODO:


  end


  context "The Websocket Server" do

    it "should register a new pipe with the data handling process when a new connection is received" do

    end

    # it "should close the websocket properly when requested" do
    #

    # it "should require all neccessary fields be present in the Upgrade request"
    # https://datatracker.ietf.org/doc/html/rfc6455#section-4.2.1

    # it "should require valid version of the websocket protocol"
    # https://datatracker.ietf.org/doc/html/rfc6455#section-4.4

    # it "should be able to receive large websocket messages" do
    # https://datatracker.ietf.org/doc/html/rfc6455#section-5.2
    # handle extended payload length (and extended payload length continued)

  end

  context "The HTTP Server" do


    end

   after(:context) do
     # Kill the server after every context.
     @server.kill
     $VERBOSE = nil
     ARGV = @saved_ARGV
     $VERBOSE = @saved_VERBOSE
   end
end
