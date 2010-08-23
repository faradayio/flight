require 'rubygems'
unless ENV['NOBUNDLE']
  begin
    require 'bundler'
    Bundler.setup
  rescue LoadError
    puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
  end
end

begin
  require 'jeweler'                                                                 
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
    gem.add_development_dependency 'activerecord', '3.0.0.beta4'
    gem.add_development_dependency 'bundler', '>=1.0.0.beta.2'
    gem.add_development_dependency 'cucumber', '=0.8.3'
    gem.add_development_dependency 'jeweler', '=1.4.0'
    gem.add_development_dependency 'rake'
    gem.add_development_dependency 'rdoc'
    gem.add_development_dependency 'rspec', '= 2.0.0.beta.17'
    gem.add_development_dependency 'sniff', '=0.1.8' unless ENV['LOCAL_SNIFF']
    gem.add_dependency 'emitter', '>=0.0.4' unless ENV['LOCAL_EMITTER']
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

unless ENV['NOBUNDLE']
  begin
    require 'sniff'
    require 'sniff/tasks'
  rescue LoadError
    puts 'Sniff gem not found, sniff tasks unavailable'
  end

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
  
  task :test => :features
  task :default => :features
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "flight #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
