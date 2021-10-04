Gem::Specification.new do |s|
  s.name        = 'easel-dashboard'
  s.version     = '0.5'
  s.executables << 'easel'
  s.licenses    = ['MIT']
  s.summary     = 'An easier way to manage your server.'
  s.authors     = ['Eric Power']
  s.email       = 'ericpower@outlook.com'
  s.files       = Dir['lib/*.rb'] + Dir['lib/html/*.erb'] + Dir['lib/easel/*.rb']
  s.homepage    = 'https://github.com/epwr/easel-dashboard'
  s.add_development_dependency 'rake', '~>13'
  s.add_runtime_dependency 'concurrent-ruby', '=1.1.9'
end
