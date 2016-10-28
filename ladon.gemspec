Gem::Specification.new do |s|
  s.name        = 'ladon'
  s.version     = '1.0.0'
  s.date        = '2016-10-27'
  s.summary     = 'Ladon'
  s.description = 'Ladon allows you to model software as graphs and create automation leveraging those models.'
  s.authors     = ['Shayne Snow']
  s.email       = 'ssnow@athenahealth.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    = 'http://rubygems.org/gems/ladon'
  s.license     = 'MIT'
  s.executables << 'ladon-run'
  s.executables << 'ladon-recorder'
end