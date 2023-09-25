# frozen_string_literal: true

module Forms
  # Exports a form to a human readable format for science!
  class Export
    COLUMNS = %w[
      Level Type Code Prompt Required? Repeatable? SkipLogic Constraints
      DisplayLogic DisplayConditions Default Hidden
    ].freeze

    OPERATIONS = {
      "eq" => "=",
      "neq" => "!=",
      "lt" => "<",
      "leq" => "<=",
      "gt" => ">",
      "geq" => ">="
    }.freeze

    QTYPE_TO_XLS = {
      # conversions
      "location" => "geopoint",
      "long_text" => "text",
      "datetime" => "dateTime",
      "annotated_image" => "image",
      "counter" => "integer",

      # no change
      "text" => "text",
      "select_one" => "select_one",
      "select_multiple" => "select_multiple",
      "decimal" => "decimal",
      "time" => "time",
      "date" => "date",
      "image" => "image",
      "barcode" => "barcode",
      "audio" => "audio",
      "video" => "video",
      "integer" => "integer",

      # Not supported in XLSForm
      "sketch" => "sketch (WARNING: not supported)",
      "signature" => "signature (WARNING: not supported)",

      # XLSForm qtypes not supported in NEMO: range, geotrace, geoshape, note, file, select_one_from_file, select_multiple_from_file, background-audio, calculate, acknowledge, hidden, xml-external
    }.freeze

    def initialize(form)
      @form = form
    end

    def to_csv
      CSV.generate do |csv|
        csv << COLUMNS
        @form.preordered_items.each do |q|
          csv << row(q)
        end
      end
    end

    # rubocop:disable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize, Metrics/PerceivedComplexity
    def to_xls
      # TODO
      # option set "levels"?
      # Make question types compatible with XLSForm, e.g., "long_text" should just be "text", "counter" does not exist, etc.

      book = Spreadsheet::Workbook.new

      # Create sheets
      questions = book.create_worksheet(name: "survey")
      choices = book.create_worksheet(name: "choices")
      settings = book.create_worksheet(name: "settings")

      # Write sheet headings at row index 0
      questions.row(0).push("type", "name", "label", "required", "relevant", "constraint")
      choices.row(0).push("list_name", "name", "label")
      settings.row(0).push("form_title", "form_id", "version", "default_language")

      group_depth = 1 # assume base level
      repeat_depth = 1
      index_mod = 1 # start at row index 1
      choices_index_mod = 0

      @form.preordered_items.each_with_index do |q, i|
        # did one or more groups just end?
        # if so, the qing's depth will be smaller than the depth counter
        while group_depth > q.ancestry_depth
          # are we in a repeat group?
          # we don't want to end the repeat if we are ending a nested non-repeat group within a repeat
          if repeat_depth > 1 && repeat_depth >= group_depth
            questions.row(i + index_mod).push("end repeat")
            repeat_depth -= 1
          else
            # end the group
            questions.row(i + index_mod).push("end group")
          end

          # update counters
          group_depth -= 1
          index_mod += 1
        end

        if q.group? # is this a group?
          if q.repeatable?
            questions.row(i + index_mod).push("begin repeat", q.code)
            repeat_depth += 1
          else
            questions.row(i + index_mod).push("begin group", q.code)
          end

          # update counters
          group_depth += 1
        else # is this a question?
          # do we have an option set?
          if q.option_set_id.present?
            os = OptionSet.find(q.option_set_id)
            os_name = " #{os.name}" # to respect XLSForm format

            os.option_nodes.each_with_index do |node, x|
              if node.option.present?
                choices.row(x + choices_index_mod).push(os.name, node.option.canonical_name, node.option.canonical_name)
              end
            end

            # increment the choices index by how many nodes there are, so we start at this row next time
            choices_index_mod += os.option_nodes.length
          else
            os_name = ""
          end

          # convert question types
          qtype_converted = QTYPE_TO_XLS[q.qtype_name]

          type_to_push = "#{qtype_converted}#{os_name}"
          code_to_push = "#{q.full_dotted_rank}_#{q.code}"

          # Write the question row
          questions.row(i + index_mod).push(type_to_push, code_to_push, q.name, q.required.to_s)
        end

        # if we have any relevant conditions, add them to the end of the row
        if q.display_conditions.any?
          questions.row(i + index_mod).push(conditions_to_xls(q.display_conditions, q.display_if))
        else
          questions.row(i + index_mod).push("")
        end

        if q.constraints.any?
          q.constraints.each do |c|
            questions.row(i + index_mod).push(conditions_to_xls(c.conditions, c.accept_if))
          end
        end
      end

      # Settings
      settings.row(1).push(@form.name, @form.id, @form.updated_at.to_s, "English (en)")

      # Write
      file = StringIO.new
      book.write(file)
      file.string.html_safe
    end
    # rubocop:enable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize, Metrics/PerceivedComplexity

    private

    def human_readable(klass, qing)
      plural_method = klass == Condition ? "display_conditions" : klass.model_name.plural
      qing.send(plural_method).map do |item|
        "#{klass}Decorator".constantize.decorate(item).human_readable
      end.join("|")
    end

    def row(qing)
      [
        qing.full_dotted_rank, qing.qtype_name, qing.code, name(qing),
        qing.required, qing.repeatable?, human_readable(SkipRule, qing),
        human_readable(Constraint, qing), qing.display_if, human_readable(Condition, qing),
        qing.default, qing.hidden
      ]
    end

    def name(qing)
      if qing.respond_to?(:name)
        qing.name
      elsif qing.repeatable?
        "Repeat Group"
      else
        "Group"
      end
    end

    def to_number(value)
      return if value.blank?
      (value.to_f % 1).positive? ? value.to_f : value.to_i
    end

    # Takes an array of conditions and outputs a single string
    # concatenates by either "and" or "or" depending on form settings
    def conditions_to_xls(conditions, true_if)
      relevant_to_push = ""
      concatenator = true_if == "all_met" ? "and" : "or"

      # how many conditions?
      dc_length = conditions.length

      conditions.each_with_index do |dc, i|
        # prep left side of expression
        left_qing = Questioning.find(dc.left_qing_id)
        left_to_push = "${#{left_qing.full_dotted_rank}_#{left_qing.code}}"

        # prep right side of expression
        if dc.right_side_is_qing?
          right_qing = Questioning.find(dc.right_qing_id)
          right_to_push = "${#{right_qing.full_dotted_rank}_#{right_qing.code}}"
        elsif Float(dc.value, exception: false).nil? # it's not a number
          # to respect XLSform rules, surround with single quotes unless it's a number
          right_to_push = "'#{dc.value}'"
        else
          right_to_push = dc.value.to_s
        end

        op = OPERATIONS[dc.op]

        # omit the concatenator on the last condition only
        relevant_to_push = if i + 1 == dc_length
                             "#{relevant_to_push}#{left_to_push} #{op} #{right_to_push}"
                           else
                             "#{relevant_to_push}#{left_to_push} #{op} #{right_to_push} #{concatenator} "
                           end
      end
      return relevant_to_push
    end
  end
end
