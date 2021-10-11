#!/bin/env ruby
#
# Author: Eric Power
#
# Description:
#     Provides the functions to provide easy logging for the Easel Dashboard.

# Imports
require 'time'


def log_fatal *msg
  unless $config[:logging] == 0
    $config[:log_file].puts "[#{Time.new.strftime("%Y-%m-%d-%H:%M:%S")}] FATAL: " + msg.join(" ")
  end
  exit 1
end

def log_error *msg
  unless $config[:logging] < 1
    $config[:log_file].puts "[#{Time.new.strftime("%Y-%m-%d-%H:%M:%S")}] ERROR: " + msg.join(" ")
  end
end

def log_warning *msg
  unless $config[:logging] < 2
    $config[:log_file].puts "[#{Time.new.strftime("%Y-%m-%d-%H:%M:%S")}] WARNING: " + msg.join(" ")
  end
end

def log_info *msg
  unless $config[:logging] < 3
    $config[:log_file].puts "[#{Time.new.strftime("%Y-%m-%d-%H:%M:%S")}] INFO: " + msg.join(" ")
  end
end
