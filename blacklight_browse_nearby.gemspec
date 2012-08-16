$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "blacklight_browse_nearby/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "blacklight_browse_nearby"
  s.version     = BlacklightBrowseNearby::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of BlacklightBrowseNearby."
  s.description = "TODO: Description of BlacklightBrowseNearby."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.1"
  s.add_dependency "blacklight"
  
  s.add_development_dependency "combustion"
  s.add_development_dependency "rspec"
end
