#!/snap/bin/ruby
#
# Author: Eric Power
#
# Description:
#     Collects information about the system to display via the Easel dashboard.
#     Uses semaphores and mutexes to provide atomic reads and writes. Allows a
#     single writer at a time, but any number of readers can read at once.
#
#     WARNING: this feature currently holds all infomration in memory, so don't
#     turn this on if you're expecting to leave Easel running for a long time.

# Imports
require 'thread'
require 'concurrent'

# Key Variables
@collected_data = {}
@writers_semaphore = Concurrent::Semaphore.new(0)  # Used to count currently active writers
@readers_semaphore = Concurrent::Semaphore.new(0)  # Used to count currently active readers
@join_mutex = Mutex.new

# launch_data_collection
#
# Launch a background thread to start collecting system info in the background.
def launch_data_collection
  Thread.new do
    loop do
      collect_data
      sleep $config[:collect_data_period]
    end
  end
end


# collect_data
#
# Collects information on the current state of the system, and writes it to
# @collected_data.
def collect_data
  new_data = {}

  if $config[:uptime] or $config[:load]
    value = read_uptime_and_load
    unless value.nil?
      new_data[:uptime] = value[0] if $config[:config]
      if $config[:load]
        new_data[:load] = value[1..-1]
      end
    end
  end

  write_data new_data
end


# read_uptime_and_load
#
# Reads the current uptime and load information using the `uptime` command and
# returns them as an array of [uptime, 1 min load, 5 min load, 15 min load]
def read_uptime_and_load
  output = `uptime`
  begin
    uptime = output.match(/up.*(\d+:\d+),/)[1]
    loads = output.match(/load average.*(\d+.\d+), (\d+.\d+), (\d+.\d+)/)
    load_1m = loads[1]
    load_5m = loads[2]
    load_15m = loads[3]
    [uptime, load_1m, load_5m, load_15m]  # Return values as array to allow destructuring.
  rescue NoMethodError => e
    log_error "`uptime` returned value that failed to parse: '#{output}'"
    nil
  end
end


# write_data
#
# Writes the data collected to @collected_data, and handles the Readers/Writer
# problem by using semaphores and a mutex.
def write_data data

  loop do
    @join_mutex.synchronize {
      if @readers_semaphore.available_permits == 0 and @writers_semaphore.available_permits == 0
        @writers_semaphore.release 1  # Increment @writers_semaphore
        break
      end
    }
    sleep 0.05  # Wait 50ms to give another thread time to lock the @join_mutex.
  end

  # Write Data
  data.each_key { |key|
    case key
    when :load
      @collected_data[:load] << data[:load]
    else
      @collected_data[key] = data[key]
    end
  }

  # Log if the @collected_data has gotten too large.
  if @collected_data[:load].length > 240
    if @collected_data[:load].length > 1000
      log_error "Easel dashboard has run collect_data more than a 1000 times. Memory size likely to be large."
    else
      log_warning "Easel dashboard starting to take up a lot of memory due to data_collection being turned on."
    end
  end

  @writers_semaphore.acquire 1  # Decrement @writers_semaphore
end


# read_data
#
# Reads (copies) @collected_data, and handles the Readers/Writer
# problem by using semaphores and a mutex. Returns a copy
def read_data

  puts "---- in read_data"
  joined = false
  until joined
    puts "---- starting loop"
    @join_mutex.synchronize {
      puts "---- mutex locked"
      if @writers_semaphore.available_permits == 0
        @readers_semaphore.release 1  # Increment @readers_semaphore
        puts "---- semaphore incremented"
        # TODO: likely need to release the mutex.
        joined = true
      end
    }
    puts "---- mutex unlocked"
    sleep 0.05 unless joined  # Wait 50ms to give another thread time to lock the @join_mutex.
  end

  puts "---- out of joining section."
  STDOUT.flush
  # TODO: stuck here and I don't get why.
  # Read Data
  data = collect_data.dup

  puts "---- acquire semaphore"
  STDOUT.flush
  @readers_semaphore.acquire 1  # Decrement @readers_semaphore
  puts "---- semaphore acquired"
  data
end
