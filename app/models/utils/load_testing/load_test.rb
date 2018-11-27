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

      def name
        self.class.name.demodulize.underscore.gsub(/_load_test/, "")
      end

      def path
        dir = "#{name}_#{timestamp.strftime('%Y%m%d%H%M%S')}"
        Rails.root.join("tmp", "load_tests", dir)
      end

      def write_file(filename, content)
        File.open(path.join(filename), "w") { |f| f.write(content) }
      end

      def dsl
        Utils::LoadTesting::Dsl.new
      end

      def test(&block)
        RubyJmeter.dsl_eval(dsl) do
          defaults(
            domain: configatron.url.host,
            port: configatron.url.port.to_i,
            protocol: configatron.url.protocol
          )

          threads(count: options[:thread_count], duration: options[:duration]) do
            instance_eval(&block)
          end
        end
      end

      # This outputs the test plan (and supporting files) to tmp/test_plans/<name>_<timestamp>/
      # The test plan can be run by copying those files to the test machine and running
      #   jmeter -n -t testplan.jmx
      def generate
        @timestamp = Time.zone.now
        FileUtils.mkdir_p(path)

        generate_test_data
        plan.jmx(file: path.join("testplan.jmx"))
        path
      end
    end
  end
end
