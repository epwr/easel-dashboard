#!/snap/bin/ruby
#
# Author: Eric Power

# Imports
require 'erb'


def build_app
  app_erb = File.new("#{File.dirname(__FILE__)}/../html/app.html.erb").read
  puts "=============================================="
  puts ERB.new(app_erb).result()
  puts "=============================================="
  "This is a thing."
end
