# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby/reports/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby-reports'
  spec.version       = Ruby::Reports::VERSION
  spec.authors       = ['Sergey D.']
  spec.email         = ['sclinede@gmail.com']

  spec.summary       = 'Make your custom reports from any source to CSV by provided DSL'
  spec.description   = 'Make your custom reports from any source to CSV by provided DSL'
  spec.homepage      = 'https://github.com/sclinede/ruby-reports'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'iron-dsl'
  spec.add_runtime_dependency 'attr_extras'
  spec.add_runtime_dependency 'facets'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec', '>= 2.14.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'timecop', '~> 0.7.1'
end
