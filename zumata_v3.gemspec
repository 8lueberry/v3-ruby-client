# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zumata_v3/version'

Gem::Specification.new do |spec|
  spec.name          = "zumata_v3"
  spec.version       = ZumataV3::VERSION
  spec.authors       = ["Jonathan Gomez", "Martin Koh"]
  spec.email         = ["enquiry@zumata.com"]
  spec.summary       = %q{Client for the Zumata API 3.0}
  spec.description   = %q{Power a hotel website - search hotels, create and manage bookings.}
  spec.homepage      = "https://github.com/Zumata/v3-ruby-client"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "3.1.0"
  spec.add_development_dependency "vcr", "2.9.3"
  spec.add_development_dependency "webmock", "1.18.0"

  spec.add_runtime_dependency 'httparty', '~> 0.13', '>= 0.13.1'

end
