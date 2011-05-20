require 'bundler'
Bundler.setup

require 'cucumber'
require 'cucumber/formatter/unicode' # Remove this line if you don't want Cucumber Unicode support

require 'sniff'
Sniff.init File.join(File.dirname(__FILE__), '..', '..'), :earth => [:air, :locality, :fuel], :cucumber => true, :logger => 'log/test_log.txt'
