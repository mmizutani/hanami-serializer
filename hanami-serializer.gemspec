# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hanami/serializer/version'

Gem::Specification.new do |spec|
  spec.name          = "hanami-serializer"
  spec.version       = Hanami::Serializer::VERSION
  spec.authors       = ["Anton Davydov"]
  spec.email         = ["antondavydov.o@gmail.com"]

  spec.summary       = %q{Serializer library for hanami applications}
  spec.description   = %q{Serializer library for hanami applications}
  spec.homepage      = "https://github.com/davydovanton/hanami-serializer"
  spec.license       = "MIT"


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-struct", "~> 0.4"
  spec.add_dependency "dry-types", "~> 0.12"

  spec.add_development_dependency "hanami-model"
  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
