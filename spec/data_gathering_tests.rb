#!/bin/env ruby
#
# Author: Eric Power
#
# Description:
#     Behavioural driven unit tests for the data_gathering process.
#
#     All tests are based on the idea that TCP sockets can be mocked by pipes.

# Imports
require 'timeout'
require_relative '../lib/easel/data_gathering.rb'

# Key Variables
$config = {
  logging: 0  # Turn off logging output.
}

describe "DataGathering Process" do

  before(:context) do
    @dh_ractor = launch_data_collection
  end

  context "Basic messaging" do

    it "should accept a writable pipe and write 'Accepted\n' to it." do
      r, w = IO.pipe
      @dh_ractor.send(w)
      expect(r.gets).to eq("Accepted\n")
    end

    it "should accept an Array with a [writable, readable] pipes and write 'Accepted\n' to it." do
      r, w = IO.pipe
      @dh_ractor.send(w)
      expect(r.gets).to eq("Accepted\n")
    end

  end

end
