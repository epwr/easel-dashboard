#!/snap/bin/ruby
#
# Author: Eric Power

# Imports
require 'erb'

# Key Variables
@code_names = {
  200 => "OK",
  400 => "Bad Request",
  404 => "Not Found",
  405 => "Forbidden",
  418 => "I'm a teapot",
  500 => "Internal Server Error"
}

# build_app
#
#
def build_app
  app_erb = File.new("#{File.dirname(__FILE__)}/../html/app.html.erb").read
  page = ERB.new(app_erb).result()

  "HTTP/1.1 200 OK\r\n" +
  "Content-Type: text/html; charset=UTF-8\r\n" +
  "Content-Length: #{page.bytesize}\r\n" +
  "Connection: close\r\n" +
  "\r\n" +
  page
end

# build_js
#
#
def build_js
  js_erb = File.new("#{File.dirname(__FILE__)}/../html/controller.js.erb").read
  page = ERB.new(js_erb).result()

  "HTTP/1.1 200 OK\r\n" +
  "Content-Type: text/javascript; charset=UTF-8\r\n" +
  "Content-Length: #{page.bytesize}\r\n" +
  "Connection: close\r\n" +
  "\r\n" +
  page
end


# return_js
#
#
def return_js file

  page = File.new("#{File.dirname(__FILE__)}/../html/#{file}").read

  "HTTP/1.1 200 OK\r\n" +
  "Content-Type: text/javascript; charset=UTF-8\r\n" +
  "Content-Length: #{page.bytesize}\r\n" +
  "Connection: close\r\n" +
  "\r\n" +
  page
end

# return_html
#
#
def return_html file

  page = File.new("#{File.dirname(__FILE__)}/../html/#{file}").read

  "HTTP/1.1 200 OK\r\n" +
  "Content-Type: text/html; charset=UTF-8\r\n" +
  "Content-Length: #{page.bytesize}\r\n" +
  "Connection: close\r\n" +
  "\r\n" +
  page
end

# build_css
#
#
def build_css
  error_erb = File.new("#{File.dirname(__FILE__)}/../html/app.css.erb").read
  css = ERB.new(error_erb).result(binding)

  "HTTP/1.1 200 OK\r\n" +
  "Content-Type: text/css; charset=UTF-8\r\n" +
  "Content-Length: #{css.bytesize}\r\n" +
  "Connection: close\r\n" +
  "\r\n" +
  css
end


# build_error
#
#
def build_error code
  error_erb = File.new("#{File.dirname(__FILE__)}/../html/error.html.erb").read
  page = ERB.new(error_erb).result(binding)

  "HTTP/1.1 #{code} #{@code_names[code]}\r\n" +
  "Content-Type: text/html; charset=UTF-8\r\n" +
  "Content-Length: #{page.bytesize}\r\n" +
  "Connection: close\r\n" +
  "\r\n" +
  page
end
