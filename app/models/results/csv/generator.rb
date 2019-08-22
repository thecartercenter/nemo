# frozen_string_literal: true

module Results
  module Csv
    # Generates CSV from responses in an efficient way. Built to handle millions of Answers.
    class Generator
      attr_accessor :buffer, :answer_processor, :header_map, :response_scope

      def initialize(response_scope)
        self.response_scope = response_scope
        self.header_map = HeaderMap.new
        self.buffer = Buffer.new(header_map: header_map)
        self.answer_processor = AnswerProcessor.new(buffer)
      end

      # Runs the queries and writes the CSV to a temp file
      # Returns temp file
      def export
        setup_header_map

        tempfile = Tempfile.new

        UserFacingCSV.open(tempfile.path, "wb", row_sep: configatron.csv_row_separator) do |csv|
          write_header(csv)
          write_body(csv)
        end

        tempfile
      end

      private

      def setup_header_map
        header_map.add_common(%w[response_id shortcode form_name user_name submit_time reviewed])
        header_map.add_group(%w[parent_group_name parent_group_depth])
        header_map.add_from_qcodes(HeaderQuery.new(response_scope: response_scope).run.to_a.flatten)
      end

      def write_header(csv)
        csv << ["\xEF\xBB\xBF"] + header_map.translated_headers
      end

      def write_body(csv)
        buffer.csv = csv
        AnswerQuery.new(response_scope: response_scope).run.each do |row|
          buffer.process_row(row)
          answer_processor.process(row)
        end
        buffer.finish
      end
    end
  end
end
