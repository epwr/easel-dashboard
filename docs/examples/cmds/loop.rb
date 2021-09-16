#!/snap/bin/ruby
#
# Author: Eric Power


(0..5).each { |num|
  sleep 1
  STDOUT.puts "To STDOUT: Hi    - #{Time.now} - #{num}"
  STDOUT.flush
  sleep 0.5
  STDERR.puts "To STDERR: Hello - #{Time.now} - #{num}"
  STDERR.flush
}
