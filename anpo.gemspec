# frozen_string_literal: true

require_relative "lib/anpo/version"

Gem::Specification.new do |spec|
  spec.name          = "anpo"
  spec.version       = Anpo::VERSION
  spec.authors       = ["TOKITA, Hiroshi"]
  spec.email         = ["tokita.hiroshi@gmail.com"]

  spec.summary       = "A nutty pofile parser"
  spec.description   = "Simple and stupidly pofile parser."
  spec.homepage      = "https://github.com/soburi/anpo"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/soburi/anpo"
  spec.metadata["changelog_uri"] = "https://github.com/soburi/anpo/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
