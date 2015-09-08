# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "malt-houston/version"

Gem::Specification.new do |s|
  s.name        = "malt-houston"
  s.authors     = ["Koji Murata"]
  s.email       = "malt.koji@gmail.com"
  s.license     = "MIT"
  s.homepage    = "https://github.com/malt03/malt-houston"
  s.version     = MaltHouston::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = "fork from Houston"
  s.description = "fork from Houston (https://github.com/nomad/houston)"

  s.add_dependency "commander", "~> 4.1"
  s.add_dependency "json"

  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "simplecov"

  s.files         = Dir["./**/*"].reject { |file| file =~ /\.\/(bin|log|pkg|script|spec|test|vendor)/ }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
