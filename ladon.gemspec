require File.expand_path('../lib/ladon/_version', __FILE__)
require 'date'

Gem::Specification.new do |gem|
  gem.name        = 'ladon'
  gem.version     = Ladon::Version::STRING
  gem.date        = Date.today.to_s
  gem.summary     = 'Ladon'
  gem.description = <<-EOF
    Ladon allows you to create software models and to create automation scripts that work through those models.
  EOF
  gem.authors     = ['Shayne Snow']
  gem.email       = 'ssnow@athenahealth.com'

  # add the runners/ directory to the load path and packaged files
  gem.require_paths = %w(lib runners)
  gem.files       = Dir['lib/**/*.rb', 'runners/**/*.rb']

  gem.homepage    = 'http://rubygems.org/gems/ladon'
  gem.license     = 'MIT' # TODO

  gem.executables << 'ladon-run'
  gem.executables << 'ladon-batch'
  gem.executables << 'ladon-flags'

  gem.required_ruby_version = '>= 2.1.0' # due to use of required keyword args
  gem.add_runtime_dependency 'pry', '~> 0.10' # for interactive mode support in ladon-run
  gem.add_runtime_dependency 'nokogiri', '~> 1.7' # for junit generation

  # NOT REQUIRED: install this gem to get byebug features baked into pry sessions
  # s.add_runtime_dependency 'pry-byebug'

  # NOT REQUIRED: install this gem to
  # s.add_runtime_dependency 'pry-stack_explorer' # for interactive mode support in ladon-run

  gem.add_dependency 'rake', '~> 11.3'
  gem.add_development_dependency 'rspec', '~> 3.5' # for specs
  gem.add_development_dependency 'rubocop', '~> 0.45' # for linting
end
