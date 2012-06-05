# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "flight/version"

Gem::Specification.new do |s|
  s.name = %q{flight}
  s.version = BrighterPlanet::Flight::VERSION
  
  s.authors = ["Andy Rossmeissl", "Seamus Abshere", "Ian Hough", "Matt Kling", "Derek Kastner"]
  s.date = %q{2011-02-25}
  s.summary = %q{Brighter Planet's impact model for flights}
  s.description = %q{Brighter Planet's impact model for flights}
  s.email = %q{andy@rossmeissl.net}
  s.homepage = %q{https://github.com/brighterplanet/flight}
  
  s.extra_rdoc_files = [
    "LICENSE",
    "LICENSE-PREAMBLE",
    "README.markdown"
  ]
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency 'earth',        '~>0.11.15'
  s.add_runtime_dependency 'emitter',      '~>0.11.1'
  s.add_runtime_dependency 'charisma',     '>=0.3.4'
  s.add_runtime_dependency 'cohort_analysis'
  s.add_runtime_dependency 'fuzzy_match'
  s.add_runtime_dependency 'weighted_average', '>=2'
  s.add_development_dependency 'sniff', '~>0.11.3'
end
