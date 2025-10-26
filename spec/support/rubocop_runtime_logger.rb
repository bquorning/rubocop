# frozen_string_literal: true

require 'parallel_tests'
require 'parallel_tests/rspec/runtime_logger'

class RuboCopRuntimeLogger < ParallelTests::RSpec::RuntimeLogger
  RSpec::Core::Formatters.register(self, :example_group_started, :example_group_finished, :start_dump, :close)

  def close(_notification)
    super

    return unless ParallelTests.first_process?

    ParallelTests.wait_for_other_processes_to_finish

    result = File.read(output.path)

    # Order all results from slowest to fastest
    ordered_results = result.lines.map { |line| Result.new(line) }.sort

    File.write(output.path, ordered_results.join)
  end

  class Result
    include Comparable

    attr_reader :path
    attr_reader :time

    # Initialize with e.g.
    # spec/foo/bar_spec:0.12345\n
    def initialize(line)
      line.scan(/(.+):([\d\.]+)/) do |path, time|
        @path = path
        @time = time.to_f
      end
    end

    def rounded_time
      Float(10 ** Math.log10(time).ceil)
    end

    # Output as e.g.
    # spec/foo/bar_spec:0.1\n
    def to_s
      "#{path}:#{rounded_time}\n"
    end

    def <=>(other)
      [-rounded_time, path] <=> [-other.rounded_time, other.path]
    end
  end
end
