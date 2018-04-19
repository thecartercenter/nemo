# frozen_string_literal: true

module Results
  module Csv
    # Generates CSV from responses in an efficient way. Built to handle millions of Answers.
    class Generator
      attr_accessor :buffer, :answer_processor, :header_map, :response_scope

      def initialize(response_scope)
        self.response_scope = response_scope
        self.header_map = HeaderMap.new
        self.buffer = Buffer.new(max_depth: 1, header_map: header_map)
        self.answer_processor = AnswerProcessor.new(buffer)
      end

      # Runs the queries and returns the CSV as a string.
      def to_s
        setup_header_map
        buffer.prepare
        csv_body.prepend(csv_headers)
      end

      private

      def setup_header_map
        header_map.add_common_headers(%w[response_id shortcode form_name user_name submit_time])
        header_map.add_group_headers(1)
        header_map.add_headers_from_codes(HeaderQuery.new(response_scope: response_scope).run.to_a.flatten)
      end

      def csv_body
        CSV.generate(row_sep: configatron.csv_row_separator) do |csv|
          buffer.csv = csv
          AnswerQuery.new(response_scope: response_scope).run.each do |row|
            buffer.process_row(row)
            answer_processor.process(row)
          end
          buffer.finish
        end
      end

      def csv_headers
        CSV.generate(row_sep: configatron.csv_row_separator) do |csv|
          csv << header_map.translated_headers
        end
      end
    end
  end
end
