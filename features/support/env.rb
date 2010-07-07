require 'bundler'
Bundler.setup

require 'cucumber'
require 'cucumber/formatter/unicode' # Remove this line if you don't want Cucumber Unicode support

require 'sniff'

root = File.join(File.dirname(__FILE__), '..', '..')
FileUtils.mkdir_p(root)
Sniff::Database.init root

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'test_support/flight_record'

## How to clean your database when transactions are turned off. See
## http://github.com/bmabey/database_cleaner for more info.
#if defined?(ActiveRecord::Base)
#  begin
#    require 'database_cleaner'
#    DatabaseCleaner.strategy = :truncation
#  rescue LoadError => ignore_if_database_cleaner_not_present
#  end
#end
