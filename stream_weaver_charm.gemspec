# frozen_string_literal: true

require_relative "lib/stream_weaver_charm/version"

Gem::Specification.new do |spec|
  spec.name = "stream_weaver_charm"
  spec.version = StreamWeaverCharm::VERSION
  spec.authors = ["Forrest Chang"]
  spec.email = ["fkchang@gmail.com"]

  spec.summary = "StreamWeaver DSL for terminal UIs via Charm"
  spec.description = "Build reactive TUI applications using StreamWeaver's declarative Ruby DSL, powered by Charm's Bubbletea and Lipgloss libraries."
  spec.homepage = "https://github.com/fkchang/stream_weaver_charm"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.glob("{lib,examples}/**/*") + %w[README.md LICENSE.txt]
  spec.require_paths = ["lib"]

  spec.add_dependency "bubbletea", "~> 0.1"
  # lipgloss has Go runtime issues with multiple style creations
  # Using raw ANSI codes instead until that's fixed
  # spec.add_dependency "lipgloss", "~> 0.2"
end
