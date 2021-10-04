#!/snap/bin/ruby
#
# Author: Eric Power
#
# Description:
#     Collects information about the system to display via the Easel dashboard.
#     Uses semaphores and mutexes to provide atomic reads and writes. Allows a
#     single writer at a time, but any number of readers can read at once.
#
#     WARNING: this feature currently holds all information in memory, so don't
#     turn this on if you're expecting to leave Easel running for a long time.
#
#     Plan for adressing this:
#       - Move 'historical' data to a proper datastore (eg. a SQLite database)
#       - Have only the most recent readings in @collected_data, to allow the
#         websocket threads to pull the up to date data from there.
#       - Eventually allow the clients to query the historial datastore, so it's
#         likely that the best bet is to have the database store the data with
#         the time as the dense index.


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

  # TODO: Check which element type something is to figure out how to handle it.

  log_info "Collecting data."
  $config[:dashboards].each{ |dashboard|

    new_data[dashboard[:id]] = {}
    dashboard[:elements].each_with_index{ |element, e_index|
      new_data[dashboard[:id]][e_index] = {}

      element[:data].each_with_index{ |data, index|
        output = `#{data[:cmd]}`
        log_info "Ran `#{data[:cmd]}`, got: #{output}"
        begin
          value = output.match(/#{data[:regex]}/)[1]
        rescue NoMethodError => e
          log_error "Data failed to be parsed. Regex: /#{data[:regex]}/ -- Output: #{output}"
        end
        new_data[dashboard[:id]][e_index][index] = [
          Time.new.strftime("%H:%M:%S"),
          value
        ]
      }
    }
  }
  write_data new_data
end


# write_data
#
# Writes the data collected to @collected_data, and handles the Readers/Writer
# problem by using semaphores and a mutex.
def write_data data

  joined = false
  until joined
    p @join_mutex
    @join_mutex.synchronize {
      if @readers_semaphore.available_permits == 0 and @writers_semaphore.available_permits == 0
        @writers_semaphore.release 1  # Increment @writers_semaphore
        joined = true
      end
    }
    sleep 0.05  # Wait 50ms to give another thread time to lock the @join_mutex.
  end

  # Write Data
  data.each_key { |key|
    case key
    when :load
      @collected_data[:load] = [] if @collected_data[:load].nil?
      @collected_data[:load] << data[:load]
    else
      @collected_data[key] = data[key]
    end
  }

  # Log if @collected_data has gotten too large.
  if not @collected_data[:load].nil? and @collected_data[:load].length > 240
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

  joined = false
  until joined
    @join_mutex.synchronize {
      if @writers_semaphore.available_permits == 0
        @readers_semaphore.release 1  # Increment @readers_semaphore
        # TODO: likely need to release the mutex.
        joined = true
      end
    }
    sleep 0.05 unless joined  # Wait 50ms to give another thread time to lock the @join_mutex.
  end

  # Read Data
  data = @collected_data.dup

  @readers_semaphore.acquire 1  # Decrement @readers_semaphore
  data
end
