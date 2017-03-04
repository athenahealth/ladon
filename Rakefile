require 'rubocop/rake_task'
require 'rubygems/tasks'
require 'rspec/core/rake_task'

# Run "rake rubocop" to run rubocop against the lib/ folder
# Run "rake rubocop:auto_correct" to run rubocop against lib/ and auto-fix where possible
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb']
end

# run "rake spec" to execute all RSpec tests
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

Gem::Tasks.new(push: false)
