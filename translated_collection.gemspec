# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'translated_collection/version'

Gem::Specification.new do |spec|
# coding: utf-8
  spec.name          = "translated_collection"
  spec.version       = TranslatedCollection::VERSION
  spec.authors       = ["Robert Sanders"]
  spec.email         = ["robert@curioussquid.com"]
  spec.summary       = %q{Transparently wrap a collection with mapping functions applied at item insertion/retrieval.}
  spec.description   = %q{Utility class for (somewhat) transparently wrapping a collection with mapping functions applied as values are added to and read from the collection. Especially useful for ActiveRecord serialized or PG Array fields}
  spec.homepage      = "http://github.com/rsanders/translated_collection"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features|gemfiles|coverage)/})
  spec.require_paths = ["lib"]

  # for testing with ActiveRecord serialized and PG Array attributes
  spec.add_development_dependency "activerecord", '~> 4.0', '>= 4.0.0'
  spec.add_development_dependency "pg", '~> 0.17', '>= 0.17.1'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "simplecov", '~> 0.9'
  spec.add_development_dependency "wwtd", '~> 0.7'
end
