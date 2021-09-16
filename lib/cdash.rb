#!/snap/bin/ruby
#
# Author: Eric Power
#
# Description:
#     Cdash turns a YAML file into a custom dashboard. See docs/configuration for
#     a description of how to set up the YAML file.

# Imports
require 'optparse'
require 'yaml'

require_relative 'cdash/logging'
require_relative 'cdash/server'
require_relative 'cdash/configuration'

# launch
#
# Launches the CDash server. Check the $config variable for defaults, although
# everything can be overridden by either the YAML file or the command line
# arguments.
def launch

  parse_ARGV

  # Load the provided YAML
  overwrite_config $config[:yaml_file]
  log_info("YAML loaded successfully (from: #{$config[:yaml_file]})")
  $config[:commands].each_with_index{ |cmd, i| cmd[:id] = i } # Give commands an ID.
  $config.freeze # Set config to read only

  # Lauch the server
  log_info("Launching server at #{$config[:hostname]}:#{$config[:port]}")
  launch_server
end


# parse_ARGV
#
# Parses the command line arguments (ARGV) using the optparse gem. Optional
# command line arguments can be seen by running this program with the -h (or
# --help) flag.
def parse_ARGV
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Useage: launch.rb [flags] configuration.yaml"

    opts.on("-h", "--help", "Prints this help message.") do
      puts opts
      exit
    end

    opts.on("-l LOG_LEVEL", "--log LOG_LEVEL", Integer, "Sets the logging level (default=2). 0=Silent, 1=Errors, 2=Warnings, 3=Info.") do |lvl|
      if [0, 1, 2, 3].include?(lvl)
        $config[:logging] = lvl
      else
        log_fatal "Command argument LOG_LEVEL '#{lvl}' not recognized. Expected 0, 1, 2, or 3."
      end
    end

    opts.on("-p PORT", "--port PORT", Integer, "Sets the port to bind to. Default is #{$config[:port]}.") do |port|
      if port >= 0 and port <= 65535
        $config[:port] = port
      else
        log_fatal "Command argument PORT '#{port}' not a valid port. Must be between 0 and 65535 (inclusive)"
      end
    end

    opts.on("-h HOST", "--hostname HOST",  "Sets the hostname. Default is '#{$config[:hostname]}'.") do |port|
      if port >= 0 and port <= 65535
        $config[:port] = port
      else
        log_fatal "Command argument PORT '#{port}' not a valid port. Must be between 0 and 65535 (inclusive)"
      end
    end

    opts.on("-o [FILE]", "--output [FILE]",  "Set a log file.") do |filename|
      begin
        $config[:log_file] = File.new(filename, "a")
      rescue Exception => e
        log_error "Log file could not be open. Sending log to STDIN. Error message: #{e}"
      end
    end
  end.parse!

  if ARGV.length != 1
    log_fatal "launch.rb takes exactly one file. Try -h for more details."
  else
    $config[:yaml_file] = ARGV[0]
  end
end


# overwrite_config
#
# Overwrites the $config fields that are set in the YAML file provided on input.
# TODO: Log (error?) every key in the YAML file that does not exist in $config.
def overwrite_config yaml_filename

  # TODO: Rewrite using pattern matching to allow checking if the
  # yaml_contents.each is one of the base keys. If so, check that the associated
  # value matches the expected nesting. Do that 'no other values' check.

  # TODO: Ensure that the command names are less than 1020 bytes (because I'm
  # setting the max length of a single websocket message to 1024 (minus 'STOP:'))

  begin
    yaml_contents = YAML.load_file $config[:yaml_file]
  rescue Exception => e
    log_fatal "YAML failed to load. Error Message: #{e}"
  end

  def loop_overwrite (config, yaml)
    yaml.each_key { |key|
        if yaml[key].is_a? Hash
          loop_overwrite(config[key.to_sym], yaml[key])
        elsif yaml[key].is_a? Array
            config[key.to_sym] = []
            yaml[key].each { |elmnt|
              element = {}
              loop_overwrite(element, elmnt)
              config[key.to_sym] << element
            }
        else
          config[key.to_sym] = yaml[key]
        end
    }
  end

  loop_overwrite($config, yaml_contents)
end


if __FILE__ == $0
  launch
end
