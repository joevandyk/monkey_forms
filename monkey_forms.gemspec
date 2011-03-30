# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "monkey_forms/version"

Gem::Specification.new do |s|
  s.name        = "monkey_forms"
  s.version     = MonkeyForms::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Joe Van Dyk"]
  s.email       = ["joe@tanga.com"]
  s.homepage    = "https://github.com/joevandyk/monkey_forms"
  s.summary     = %q{Helps make complex forms}
  s.description = %q{Helps make complex forms}

  s.rubyforge_project = "monkey_forms"
  s.add_dependency('activemodel', '>= 3.0.5')
  s.add_development_dependency 'minitest'



  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
