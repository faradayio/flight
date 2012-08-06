ENV.each do |name, value|
  if /^LOCAL_(.+)/.match(name)
    gem $1.downcase, :path => value
  end
end

source :rubygems

gemspec

gem 'earth', :path => '~/earth'
gem 'sniff', :path => '~/sniff'
gem 'emitter', :path => '~/emitter'
