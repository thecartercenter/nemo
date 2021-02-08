# frozen_string_literal: true

module Results
  module CSV
    # Generates CSV from responses in an efficient way. Built to handle millions of Answers.
    class Generator
      attr_accessor :buffer, :answer_processor, :header_map, :response_scope, :options, :locales

      def initialize(response_scope, mission:, options:)
        mission_config = mission.setting
        self.locales = mission_config.preferred_locales
        self.response_scope = response_scope
        self.options = options
        self.header_map = HeaderMap.new(locales: locales)
        self.buffer = Buffer.new(header_map: header_map)
        self.answer_processor = AnswerProcessor.new(buffer)
      end

      # Runs the queries and writes the CSV to a temp file
      # Returns temp file
      def export
        setup_header_map

        tempfile = Tempfile.new

        UserFacingCSV.open(tempfile.path, "wb") do |csv|
          write_header(csv)
          write_body(csv)
        end

        tempfile
      end

      private

      def setup_header_map
        header_map.add_common(%w[response_id shortcode form_name user_name submit_time reviewed])
        header_map.add_group(%w[parent_group_name parent_group_depth])
        qcodes = HeaderQuery.new(response_scope: response_scope, locales: locales).run.to_a.flatten
        header_map.add_from_qcodes(qcodes)
      end

      def write_header(csv)
        csv << header_map.translated_headers
      end

      def write_body(csv)
        buffer.csv = csv
        AnswerQuery.new(response_scope: response_scope, locales: locales).run.each do |row|
          buffer.process_row(row)
          answer_processor.process(row, **options)
        end
        buffer.finish
      end
    end
  end
end
