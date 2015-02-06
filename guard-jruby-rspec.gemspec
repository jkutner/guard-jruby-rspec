# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'guard/jruby-rspec/version'

Gem::Specification.new do |s|
  s.name        = 'guard-jruby-rspec'
  s.version     = Guard::JRubyRSpecVersion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Joe Kutner']
  s.email       = ['jpkutner@gmail.com']
  s.homepage    = 'http://rubygems.org/gems/guard-jruby-rspec'
  s.summary     = 'Guard gem for JRuby RSpec'
  s.description = 'Guard::JRubyRSpec keeps a warmed up JVM ready to run your specs.'

  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project         = 'guard-jruby-rspec'

  s.add_dependency 'guard', '>= 0.10.0', '< 2.0.0'
  s.add_dependency 'guard-rspec', '>= 0.7.3', '< 4.0.0'

  s.add_development_dependency 'rspec', '~> 2.7'

  s.files        = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  s.require_path = 'lib'
end
