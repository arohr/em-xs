require 'bundler'
require 'rspec/core/rake_task'

task :default => ['spec:coverage']

namespace :spec do
  desc 'Run specs with SimpleCov'
  RSpec::Core::RakeTask.new('coverage') do |t|
    ENV['COVERAGE'] = 'true'
  end
end
