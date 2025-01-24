# frozen_string_literal: true

require 'rspec/core'
require './spec/support/encoding_helper'
require './spec/support/rubocop_runtime_logger'

desc 'Run RSpec code examples'
task :spec do
  ParallelTests::CLI.new.run(%w[
    --type rspec
    --runtime-log spec/support/parallel_runtime_rspec.log
    --
    --format ParallelTests::RSpec::SummaryLogger
    --tag ~slow
    --
  ])
end

desc 'Run slow RSpec code examples'
task :slow_spec do
  ParallelTests::CLI.new.run(%w[
    --type rspec
    --runtime-log spec/support/parallel_runtime_rspec.log
    --
    --format ParallelTests::RSpec::SummaryLogger
    --tag slow
    --
  ])
end

desc 'Refresh spec runtime log'
task :refresh_spec_runtime_log do
  ParallelTests::CLI.new.run(%w[
    --type rspec
    --
    --format RuboCopRuntimeLogger
    --out spec/support/parallel_runtime_rspec.log
    --
  ])
end

desc 'Run RSpec code examples with ASCII encoding'
task :ascii_spec do
  true
  # RuboCop::SpecRunner.new(external_encoding: 'ASCII').run_specs
end

desc 'Run RSpec code examples with Prism'
task :prism_spec do
  sh('PARSER_ENGINE=parser_prism bundle exec rake spec')
end
