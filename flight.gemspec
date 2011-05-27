# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "flight/version"

Gem::Specification.new do |s|
  s.name = %q{flight}
  s.version = BrighterPlanet::Flight::VERSION
  
  s.authors = ["Andy Rossmeissl", "Seamus Abshere", "Ian Hough", "Matt Kling", "Derek Kastner"]
  s.date = %q{2011-02-25}
  s.summary = %q{A carbon model}
  s.description = %q{A software model in Ruby for the greenhouse gas emissions of a flight}
  s.email = %q{andy@rossmeissl.net}
  s.homepage = %q{http://github.com/brighterplanet/flight}
  
  s.extra_rdoc_files = [
    "LICENSE",
     "LICENSE-PREAMBLE",
     "README.markdown",
     "README.rdoc"
  ]
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency 'emitter'
  s.add_development_dependency 'sniff' unless ENV['LOCAL_SNIFF']
  s.add_development_dependency 'ruby-debug19'
end
