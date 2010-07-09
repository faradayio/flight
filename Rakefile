require 'rubygems'
require 'bundler'
Bundler.setup

require 'sniff'
require 'sniff/tasks'

require 'jeweler'                                                                 
Jeweler::Tasks.new do |gem|                                                       
  gem.name = %q{flight}
  gem.summary = %q{A carbon model}
  gem.description = %q{A software model in Ruby for the greenhouse gas emissions of a flight}
  gem.email = %q{andy@rossmeissl.net}
  gem.homepage = %q{http://github.com/brighterplanet/flight}
  gem.authors = ["Andy Rossmeissl", "Seamus Abshere", "Ian Hough", "Matt Kling", 'Derek Kastner']
  gem.files = ['LICENSE', 'README.rdoc', 'lib/flight.rb']
  gem.test_files = Dir.glob(File.join(File.dirname(__FILE__), 'features', '**/*.rb')) +
    Dir.glob(File.join(File.dirname(__FILE__), 'lib', 'test_support', '**/*.rb'))
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'bundler', '=1.0.0.beta.2'
  gem.add_development_dependency 'jeweler', '=1.4.0'
  gem.add_development_dependency 'cucumber', '=0.8.3'
  gem.add_development_dependency 'sniff', '=0.0.1' unless ENV['LOCAL_SNIFF']
  gem.add_dependency 'weighted_average', '=0.0.4'
  gem.add_dependency 'geokit', '=1.5.0'
end                                                                               
Jeweler::GemcutterTasks.new

require 'cucumber'
require 'cucumber/rake/task'

desc 'Run all cucumber tests'
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

desc "Run all tests with RCov"
Cucumber::Rake::Task.new(:features_with_coverage) do |t|
  t.cucumber_opts = "features --format pretty"
  t.rcov = true
  t.rcov_opts = ['--exclude', 'features']
end

task :default => :features

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "flight #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
