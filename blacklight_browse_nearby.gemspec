$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "blacklight_browse_nearby/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "blacklight_browse_nearby"
  s.version     = BlacklightBrowseNearby::VERSION
  s.authors     = ["Jessie Keck"]
  s.email       = ["jkeck@stanford.edu"]
  s.summary     = "Browse nearby plugin for Blacklight."
  s.description = "Browse nearby plugin for Blacklight."

  s.files = Dir["{app,config,lib}/**/*"] + ["LICENSE", "Rakefile", "README.rdoc", "SOLR_README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.1"
  s.add_dependency "blacklight"
  
  s.add_development_dependency "combustion"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "capybara"
end
