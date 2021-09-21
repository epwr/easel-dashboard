Gem::Specification.new do |s|
  s.name        = 'easel-dashboard'
  s.version     = '0.4.3'
  s.summary     = "Easily set up and serve a dashboard using only a YAML file."
  s.description = "Use a YAML file to set up a dashboard, and change everything from the page colours to the commands that can be run. The dashboard shows the output of each command, which can be used to monitor server health, running processes, and much more."
  s.authors     = ["Eric Power"]
  s.email       = 'ericpower@outlook.com'
  s.files       = Dir['lib/*.rb'] + Dir['lib/html/*.erb'] + Dir["lib/easel/*.rb"]
  s.homepage    = 'https://github.com/epwr/cdash'
  s.executables << 'easel'
  s.license     = 'MIT'

  s.add_runtime_dependency = "concurrent-ruby" ["=1.1.9"]
end
