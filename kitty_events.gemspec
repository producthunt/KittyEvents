lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitty_events/version'

Gem::Specification.new do |spec|
  spec.name          = 'kitty_events'
  spec.version       = KittyEvents::VERSION
  spec.authors       = ['Mike Coutermarsh', 'Radoslav Stankov']
  spec.email         = ['coutermarsh.mike@gmail.com', 'rstankov@gmail.com']

  spec.summary       = 'Super simple event system on top of ActiveJob'
  spec.description   = 'Super simple event system on top of ActiveJob'
  spec.homepage      = 'https://github.com/producthunt/kittyevents'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activejob', '>= 4.2'
  spec.add_development_dependency 'bundler', '~> 2.1.4'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.50'
end
