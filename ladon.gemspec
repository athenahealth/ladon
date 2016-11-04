$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'ladon/_version'

Gem::Specification.new do |s|
  s.name        = 'ladon'
  s.version     = Ladon::Version::STRING
  s.date        = '2016-11-4'
  s.summary     = 'Ladon'
  s.description = <<-EOF
    Ladon allows you to create software models and to create automation scripts that work through those models.
  EOF
  s.authors     = ['Shayne Snow']
  s.email       = 'ssnow@athenahealth.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    = 'http://rubygems.org/gems/ladon'
  s.license     = 'MIT' # TODO

  s.executables << 'ladon-run'

  s.required_ruby_version = '>= 2.1.0' # due to use of required keyword args
  s.add_runtime_dependency 'pry', '~> 0.10' # for interactive mode support in ladon-run
end
