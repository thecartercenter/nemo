module Results
  module Csv
    # Generates CSV from a collection of Responses.
    class Generator
      def initialize(responses)
        @responses = responses
        @columns = []
        @columns_by_question = {}
        @processed_forms = []

        # AttribCache is used to cache object attributes.
        # This is used to cache certain often-read attributes that tend to cause performance
        # problems due to kicking off tons of queries.
        @cache = AttribCache.new
      end

      def to_s
        @str ||= responses.empty? ? "" : generate
      end

      private

      attr_accessor :responses, :columns, :columns_by_question, :processed_forms, :cache

      def generate
        # We have to build the body first so that the headers are correct.
        b = body
        headers << b
      end

      def headers
        CSV.generate(row_sep: configatron.csv_row_separator) do |csv|
          csv << columns
        end
      end

      def body
        CSV.generate(row_sep: configatron.csv_row_separator) do |csv|
          # Initial columns
          find_or_create_column(code: "Form")
          find_or_create_column(code: "Submitter")
          find_or_create_column(code: "DateSubmitted")
          find_or_create_column(code: "ResponseUUID")
          find_or_create_column(code: "ResponseShortcode")
          if responses.any? { |r| cache[r.form, :has_repeat_group?] }
            find_or_create_column(code: "GroupName")
            find_or_create_column(code: "GroupLevel")
          end

          responses.each do |response|
            # Ensure we have all this response's columns in our table.
            process_form(response.form)

            # Split response into repeatable and non-repeatable answers. There will be one row with the non
            # repeat answers, and then one row for each repeat group answer.
            # We do eager loading here per-Response instead of all at once to avoid creating too many objects
            # in memory at once in the case of large result sets.
            answers = response.answers.
              includes(:option, questioning: {question: {option_set: :root_node}}, choices: :option).
                order("form_items.rank", "answers.inst_num", "answers.rank")
            repeatable_answers = answers.select { |a| cache[a.questioning, :repeatable?] }
            non_repeat_answers = answers - repeatable_answers

            # Make initial row
            row = [
              response.form.name,
              response.user.name,
              response.created_at.to_s(:std_datetime_with_tz),
              response.uuid,
              response.shortcode
            ]

            non_repeat_answers.group_by(&:question).each do |question, answers|
              add_question_answers_to_row(response, row, question, answers)
            end
            repeating_row_part = row.dup
            ensure_row_complete(row)
            csv << row

            # Make a row for each repeat_group answer
            repeat_groups = repeatable_answers.group_by { |a| a.questioning.parent }.sort_by { |group, _| group.rank  }
            repeat_groups.each do |repeat_group, group_answers|
              group_answers.group_by(&:inst_num).each do |inst_num, repeat_answers|
                row = repeating_row_part.dup
                repeat_answers.group_by(&:question).each do |question, answers|
                  add_question_answers_to_row(response, row, question, answers)
                end
                ensure_row_complete(row)
                csv << row
              end
            end
          end
        end
      end

      def add_question_answers_to_row(response, row, question, answers)
        return if question.multimedia?
        columns = columns_by_question[question.code]
        qa = QA.new(question, answers, cache)
        columns.each_with_index { |c, i| row[c.position] = qa.cells[i] }
        if cache[response.form, :has_repeat_group?]
          group_level = answers.first.group_level
          group_name = answers.first.parent_group_name
          row[columns_by_question["GroupName"].first.position] = group_name
          row[columns_by_question["GroupLevel"].first.position] = group_level
        end
      end

      def ensure_row_complete(row)
        if row.count < columns.count
          row[columns.count - 1] = nil
        end
      end

      def process_form(form)
        return if processed_forms.include?(form.id)
        form.questionings.each { |q| find_or_create_column(qing: q) }
        processed_forms << form.id
      end

      def find_or_create_column(code: nil, qing: nil)
        question = nil
        if code.nil?
          question = qing.question
          code = question.code
        end

        return if column_exists_with_code?(code)

        if question
          return if question.multimedia?
          name = [code]
          if cache[qing, :repeatable?]
            name = [qing.parent_group_name, code]
          end
          if cache[question, :multilevel?]
            question.levels.each_with_index do |level, i|
              create_column(code: code, name: name + [level.name])
            end
          else
            # Location questions only have lng/lat cols which are added below.
            unless question.qtype_name == 'location'
              create_column(code: code, name: name)
            end
          end
          if question.geographic?
            create_column(code: code, name: name + ['Latitude'])
            create_column(code: code, name: name + ['Longitude'])
          end
          if question.location_type?
            create_column(code: code, name: name + ['Altitude'])
            create_column(code: code, name: name + ['Accuracy'])
          end
        else
          create_column(code: code, name: name)
        end
      end

      def create_column(code: nil, name: nil)
        name ||= code
        column = Column.new(code: code, name: name, position: columns.size)
        columns << column
        columns_by_question[code] ||= []
        columns_by_question[code] << column
      end

      def column_exists_with_code?(code)
        !columns_by_question[code].nil?
      end
    end
  end
end
