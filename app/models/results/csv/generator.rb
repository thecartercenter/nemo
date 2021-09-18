# frozen_string_literal: true

module Results
  module CSV
    # Generates CSV from responses in an efficient way. Built to handle millions of Answers.
    class Generator
      attr_accessor :buffer, :answer_processor, :header_map, :response_scope, :long_text_behavior, :locales

      def initialize(response_scope, mission:, long_text_behavior:)
        mission_config = mission.setting
        self.locales = mission_config.preferred_locales
        self.response_scope = response_scope
        self.long_text_behavior = long_text_behavior
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

        # Forms that have conditional logic that leads to a question NEVER being shown to users
        # will never have that question code stored in their response tree, so here we
        # ensure that all headers get added (so that data analysts aren't confused).
        header_map.add_from_qcodes(response_form_qcodes)
      end

      def response_form_qcodes
        forms = response_scope.distinct(:form_id).includes(:form).map(&:form)
        qcodes = forms.map do |form|
          form.descendants.map do |form_item|
            form_item.instance_of?(Questioning) ? hash_from_form_item(form_item) : nil
          end.compact
        end
        qcodes.flatten.uniq { |hash| hash["code"] }
      end

      # Returns the same structure of data that HeaderQuery would return,
      # so that it can be parsed by header_map#add_from_qcodes.
      def hash_from_form_item(form_item)
        {
          "code" => form_item.question.code,
          "qtype_name" => form_item.question.qtype_name,
          "level_names" => form_item.option_set&.level_names&.to_json,
          "allow_coordinates" => form_item.option_set&.allow_coordinates
        }
      end

      def write_header(csv)
        csv << header_map.translated_headers
      end

      def write_body(csv)
        buffer.csv = csv
        AnswerQuery.new(response_scope: response_scope, locales: locales).run.each do |row|
          buffer.process_row(row)
          answer_processor.process(row, long_text_behavior: long_text_behavior)
        end
        buffer.finish
      end
    end
  end
end
