# frozen_string_literal: true

require_relative "lib/agentic_harness/version"

Gem::Specification.new do |spec|
  spec.name        = "agentic_harness"
  spec.version     = AgenticHarness::VERSION
  spec.authors     = ["Elias Baixas"]
  spec.summary     = "Lightweight Rails harness for agentic / unattended development work"
  spec.description = <<~DESC
    Drop-in Rails engine that adds a kanban over markdown task files, a
    docs viewer for in-repo markdown, and night-shift artifact surfaces
    (per-worktree TASK.md viewer + cross-worktree admin dashboard).
    Designed for projects where an autonomous Claude / agent runs work in
    parallel git worktrees and the human reviews via the browser.
  DESC
  spec.homepage    = "https://github.com/eliasbaixas/agentic-harness"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "{app,config,lib}/**/*",
    "MIT-LICENSE",
    "Rakefile",
    "README.md",
    "CHANGELOG.md"
  ]

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "redcarpet", ">= 3.5" # markdown rendering for docs + night-shift artifacts

  spec.add_development_dependency "minitest", "~> 5.0"
end
