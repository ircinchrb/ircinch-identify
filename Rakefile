# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.ruby_opts << "--debug" if RUBY_ENGINE == "jruby" # Enable full tracing for coverage.
end

require "standard/rake"

task default: %i[test standard]
