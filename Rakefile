require 'rubygems'

def require_or_fail(gems, message, failure_results_in_death = false)
  gems = [gems] unless gems.is_a?(Array)

  begin
    gems.each { |gem| require gem }
    yield
  rescue LoadError
    puts message
    exit if failure_results_in_death
  end
end

unless ENV['NOBUNDLE']
  message = <<-MESSAGE
In order to run tests, you must:
  * `gem install bundler`
  * `bundle install`
  MESSAGE
  require_or_fail('bundler',message,true) do
    Bundler.setup
  end
end

require_or_fail('jeweler', 'Jeweler (or a dependency) not available. Install it with: gem install jeweler') do
  Jeweler::Tasks.new do |gem|
    gem.name = %q{flight}
    gem.summary = %q{A carbon model}
    gem.description = %q{A software model in Ruby for the greenhouse gas emissions of a flight}
    gem.email = %q{andy@rossmeissl.net}
    gem.homepage = %q{http://github.com/brighterplanet/flight}
    gem.authors = ["Andy Rossmeissl", "Seamus Abshere", "Ian Hough", "Matt Kling", 'Derek Kastner']
    gem.files = ['LICENSE', 'README.rdoc'] + 
      Dir.glob(File.join('lib', '**','*.rb'))
    gem.test_files = Dir.glob(File.join('features', '**', '*.rb')) +
      Dir.glob(File.join('features', '**', '*.feature')) +
      Dir.glob(File.join('lib', 'test_support', '**/*.rb'))
    gem.add_development_dependency 'activerecord', '~>3'
    gem.add_development_dependency 'bundler', '~>1.0.0'
    gem.add_development_dependency 'cucumber'
    gem.add_development_dependency 'jeweler', '~>1.4.0'
    gem.add_development_dependency 'rake'
    gem.add_development_dependency 'rdoc'
    gem.add_development_dependency 'rspec', '= 2.0.1'
    gem.add_development_dependency 'sniff', '~>0.3' unless ENV['LOCAL_SNIFF']
    gem.add_dependency 'emitter', '~>0.3' unless ENV['LOCAL_EMITTER']
    gem.add_dependency 'earth', '~>0.3' unless ENV['LOCAL_EARTH']
    gem.add_dependency 'builder'
  end
  Jeweler::GemcutterTasks.new
end

require_or_fail 'emitter', 'Emitter gem not found, emitter tasks unavailable' do
  require 'emitter/tasks'
  Emitter::Tasks.new.define('flight')
end

require_or_fail('sniff', 'Sniff gem not found, sniff tasks unavailable') do
  require 'sniff/rake_task'
  Sniff::RakeTask.new(:console) do |t|
    t.earth_domains = [:air, :locality, :fuel]
  end
end

require_or_fail('cucumber', 'Cucumber gem not found, cucumber tasks unavailable') do
  require 'cucumber/rake/task'

  desc 'Run all cucumber tests'
  Cucumber::Rake::Task.new(:features) do |t|
    if ENV['CUCUMBER_FORMAT']
      t.cucumber_opts = "features --format #{ENV['CUCUMBER_FORMAT']}"
    else
      t.cucumber_opts = 'features --format pretty'
    end
  end

  desc "Run all tests with RCov"
  Cucumber::Rake::Task.new(:features_with_coverage) do |t|
    t.cucumber_opts = "features --format pretty"
    t.rcov = true
    t.rcov_opts = ['--exclude', 'features']
  end

  task :test => :features
  task :default => :test
end

require_or_fail 'rspec', 'RSpec gem not found, RSpec tasks unavailable' do
  require 'rspec/core/rake_task'
  Rspec::Core::RakeTask.new do |t|
    if ENV['CUCUMBER_FORMAT']
      t.rspec_opts = "--format #{ENV['CUCUMBER_FORMAT']}"
    else
      t.rspec_opts = '--format p'
    end
  end

  task :test => :spec
end

require 'rake/rdoctask'

Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "lodging #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
