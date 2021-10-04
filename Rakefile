
desc "Run Easel with the dash-1.yaml example file."
task default: %w[run]

desc "Run Easel with the dash-1.yaml example file."
task :run do
  sh "./lib/easel.rb ./docs/examples/dash-1.yaml"
end

desc "Run all test files"
task :test do
  sh "rspec spec/*"
end

desc "Kill any running server instances"
task :kill do
  pids = `lsof -i | grep localhost | sed 's|^ruby\\s*\\([[:digit:]]*\\).*$|\\1|'`
  pids =  pids.split("\n").map { |pid| pid.to_i }.uniq.each { |pid|
    Process.kill "INT", pid
  }
end


task :clean

namespace "gem" do

  desc 'Validates that the version number is appropriately set (v=X.X)'
  task :validate_version do
    if ENV['v'].nil? or not ENV['v'].match(/^\d+\.\d+$/)
      raise "Error: `rake create_gemspec` requires a version number."
    end
  end

  desc "Builds the .gemspec file."
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
    gemspec.puts "  s.required_ruby_version >= 2.0"
    gemspec.puts "  s.files       = Dir['lib/*.rb'] + Dir['lib/html/*.erb'] + Dir['lib/easel/*.rb']"
    gemspec.puts "  s.homepage    = 'https://github.com/epwr/easel-dashboard'"
    gemspec.puts "  s.add_development_dependency 'rake', '~>13'"
    gemspec.puts "  s.add_runtime_dependency 'concurrent-ruby', '=1.1.9'"
    gemspec.puts "end"
    gemspec.close
  end

  desc "builds a gem based on the gemspec."
  task :build => %w[validate_version] do
    sh "gem build easel.gemspec"
  end

  desc "pushes a gem to rubygems.org"
  task :push => %w[validate_version] do
    sh "gem push easel-dashboard-#{ENV['v']}.gem"
  end

  desc "Cleans up the .gem files."
  task :clean do
    Dir['*.gem'].each { |file|
      sh "rm " + file
    }
  end
end
