require_relative "lib/little_canary"

Gem::Specification.new do |s|
  s.name          = "little_canary"
  s.version       = LittleCanary::VERSION
  s.summary       = "Endpoint Detection Response tester."
  s.description   = "Endpoint Detection Response tester."
  s.authors       = ["Robert Peterson"]
  s.email         = "me@robertp.me"
  s.files         = Dir["{bin,lib}/**/*", "README.md"]
  s.test_files    = Dir["spec/**/*"]
  s.require_paths = ["lib"]
  s.executables   = ["lc"]
  s.license       = "MIT"

  s.required_ruby_version = ">= 3.1"

  s.add_development_dependency "bundler", "~> 2.5"
  s.add_development_dependency "rake", "~> 13.2"
  s.add_development_dependency "minitest", "~> 5.24"
end
