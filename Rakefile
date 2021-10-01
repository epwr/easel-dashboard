
desc "Run Easel with the dash-1.yaml example file."
task default: %w[run]

desc "Run Easel with the dash-1.yaml example file."
task :run do
  sh "./lib/easel.rb ./docs/examples/dash-1.yaml"
end

task :clean

namespace "gem" do

  desc 'Validates that the version number is appropriately set (v=X.X)'
  task :validate_version do
    if ENV['v'].nil? or not ENV['v'].match(/^\d+\.\d+$/)
      raise "Error: `rake create_gemspec` requires a version number."
    end
  end

  desc ""
  task :gemspec => %w[validate_version] do
    # Expect ARGV to be the version number

    gemspec = File.new("easel.gemspec", "w")
    gemspec.puts "Gem::Specification.new do |s|"
    gemspec.puts "  s.name        = 'easel-dashboard'"
    gemspec.puts "  s.version     = '#{ENV['v']}'"
    gemspec.puts "  s.executables << 'easel'"
    gemspec.puts "  s.licenses    = ['MIT']"
    gemspec.puts "  s.summary     = 'An easier way to manage your server.'"
    gemspec.puts "  s.authors     = ['Eric Power']"
    gemspec.puts "  s.email       = 'ericpower@outlook.com'"
    gemspec.puts "  s.files       = Dir['lib/*.rb'] + Dir['lib/html/*.erb'] + Dir['lib/easel/*.rb']"
    gemspec.puts "  s.homepage    = 'https://github.com/epwr/easel-dashboard'"
    gemspec.puts "  s.add_development_dependency 'rake', '~>13'"
    gemspec.puts "  s.add_runtime_dependency 'concurrent-ruby', '=1.1.9'"
    gemspec.puts "end"
    gemspec.close
  end

  task :build => %w[validate_version] do
    sh "gem build easel.gemspec"
  end

  task :push => %w[validate_version] do
    sh "gem push easel-dashboard-#{ENV['v']}.gem"
  end

  task :clean do
    # TODO: for .gem file, rm.
    sh "rm *.gem"
  end
end
