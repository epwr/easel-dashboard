Gem::Specification.new do |s|
  s.name        = 'easel-dashboard'
  s.version     = '0.6.2'
  s.executables << 'easel'
  s.licenses    = ['MIT']
  s.summary     = 'An easier way to manage your server.'
  s.authors     = ['Eric Power']
  s.email       = 'ericpower@outlook.com'
  s.required_ruby_version = '>= 2.6'
  s.files       = Dir['lib/*.rb'] + Dir['lib/html/*.erb'] + Dir['lib/easel/*.rb']
  s.homepage    = 'https://github.com/epwr/easel-dashboard'
  s.add_development_dependency 'rake', '~>13'
  s.add_development_dependency 'rspec', '~>3'
  s.add_development_dependency 'simplecov', '>0.21'
  s.add_runtime_dependency 'concurrent-ruby', '=1.1.9'
end
