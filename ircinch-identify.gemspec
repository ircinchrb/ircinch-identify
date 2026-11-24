# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "ircinch-identify"
  spec.version = "1.7.1"
  spec.authors = ["Matt Sias"]
  spec.email = ["mattsias@gmail.com"]

  spec.summary = "Automatic IRC services login for IRCinch bots"
  spec.description = "Signs IRCinch bots in to IRC services after connecting. Supports NickServ (including DALnet), UserServ, KreyNet's K, and QuakeNet's Q via AUTH or CHALLENGEAUTH."
  spec.homepage = "https://github.com/ircinchrb/ircinch-identify"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata = {
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/gems/ircinch-identify",
    "source_code_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["CHANGELOG.md", "LICENSE.txt", "README.md", "lib/**/*"]

  # Register runtime dependencies (gems required to run this gem)
  spec.add_dependency "ircinch", ">= 2.4.6"

  # Register development dependencies (gems required to program this gem)
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "bundler-integrity"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "standard"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
