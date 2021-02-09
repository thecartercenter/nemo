# frozen_string_literal: true

module Utils
  module LoadTesting
    # Abstract base class for load tests
    class LoadTest
      attr_reader :options, :timestamp

      # `options` is a hash containing info necessary to construct the test requests. Specifically:
      #   thread_count: The number of threads to execute.
      #   duration: How long each thread should run.
      # Other options may be required by subclasses
      def initialize(options)
        @options = options
        options[:thread_count] ||= 1
        options[:duration] ||= 1
      end

      def generate_test_data
        # To be implemented in subclasses
      end

      # This outputs the test plan (and supporting files) to tmp/test_plans/<name>_<timestamp>/
      # The test plan can be run by copying those files to the test machine and running
      #   jmeter -n -t testplan.jmx
      def generate_plan
        @timestamp = Time.current
        FileUtils.mkdir_p(path)

        generate_test_data
        plan.jmx(file: path.join("testplan.jmx"))
        path
      end

      protected

      def name
        self.class.name.demodulize.underscore.gsub(/_load_test/, "")
      end

      def path
        dir = "#{name}_#{timestamp.strftime('%Y%m%d%H%M%S')}"
        Rails.root.join("tmp/load_tests", dir)
      end

      def write_file(filename, content)
        File.open(path.join(filename), "w") { |f| f.write(content) }
      end

      def dsl
        Utils::LoadTesting::Dsl.new
      end

      def test(&block)
        RubyJmeter.dsl_eval(dsl) do
          # Normally the given `block` is evaluated in this context.
          # Since the following is common across all load tests we can capture
          # the block and evaluate it inside the `threads` block (below).
          # This alleviates needing to duplicate the following code in each test.

          defaults(
            domain: Cnfg.url_host,
            port: Cnfg.url_port,
            protocol: Cnfg.url_protocol
          )

          threads(count: options[:thread_count], duration: options[:duration]) do
            instance_eval(&block)
          end
        end
      end
    end
  end
end
