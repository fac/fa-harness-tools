lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fa-harness-tools/version"

Gem::Specification.new do |spec|
  spec.name          = "fa-harness-tools"
  spec.version       = FaHarnessTools::VERSION
  spec.authors       = ["FreeAgent"]
  spec.email         = ["opensource@freeagent.com"]

  spec.summary       = %q{Tools including preflight checks for Harness.io}
  spec.description   = %q{FreeAgent-specific pre-flight checks and tools that are designed to work in Harness.io}
  spec.homepage      = "https://github.com/fac/fa-harness-tools"
  spec.license       = "Apache-2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/fac/fa-harness-tools/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "octokit", "~> 4.0"

  spec.add_development_dependency "bundler", "~> 1.0"
  spec.add_development_dependency "rake", "~> 10.0"
end
