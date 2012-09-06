# -*- encoding: utf-8 -*-
require File.expand_path('lib/em-xs')

Gem::Specification.new do |gem|
  gem.name        = 'em-xs'
  gem.version     = EM::XS::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.summary     = 'Thin wrapper around crossroads I/O (XS) socket which can be used in combination with EventMachine.'
  gem.description = 'Thin wrapper around crossroads I/O (XS) socket which can be used in combination with EventMachine.'
  gem.licenses    = ['MIT']
  gem.authors     = ['Andy Rohr']
  gem.email       = ['andy.rohr@mindclue.ch']
  gem.homepage    = 'https://github.com/arohr/em-xs'

  gem.required_rubygems_version = '>= 1.3.6'

  gem.files         = `git ls-files`.split($\)
  gem.require_paths = ['lib']

  gem.add_dependency "ffi-rxs"
  gem.add_dependency "eventmachine", "~> 1.0.0.beta.4"

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'simplecov'
end

