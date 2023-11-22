# frozen_string_literal: true

module Forms
  # Exports a form to a human readable format for science!
  class Export
    COLUMNS = %w[
      Level Type Code Prompt Required? Repeatable? SkipLogic Constraints
      DisplayLogic DisplayConditions Default Hidden
    ].freeze

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

      # TODO: Not yet supported in our XLSForm exporter
      "sketch" => "sketch (WARNING: not yet supported)",
      "signature" => "signature (WARNING: not yet supported)"

      # Note: XLSForm qtypes not supported in NEMO:
      #   range, geotrace, geoshape, note, file, select_one_from_file, select_multiple_from_file,
      #   background-audio, calculate, acknowledge, hidden, xml-external
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

    # rubocop:disable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Style/Next
    def to_xls
      # TODO: option set "levels"?

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
      option_sets_used = []

      # Define the below "index modifiers" which keep track of the line of the spreadsheet we are writing to.
      # The for loop below (tracked by index i) loops through the list of form items, and so the index does not take into account rows that we need to write for when groups end. In XLSForm, these are written to a row all to themselves.
      # This causes the index i to be de-synchronized with the row of the spreadsheet that we are writing to.
      # Hence, we push to the row (i + index_mod)
      index_mod = 1 # start at row index 1
      choices_index_mod = 1

      @form.preordered_items.each_with_index do |q, i|
        # this variable keeps track of the spreadsheet row to be written during this loop iteration
        row_index = i + index_mod

        # did one or more groups just end?
        # if so, the qing's depth will be smaller than the depth counter
        while group_depth > q.ancestry_depth
          # are we in a repeat group?
          # we don't want to end the repeat if we are ending a nested non-repeat group within a repeat
          if repeat_depth > 1 && repeat_depth >= group_depth
            questions.row(row_index).push("end repeat")
            repeat_depth -= 1
          else
            # end the group
            questions.row(row_index).push("end group")
          end

          # update counters to accomodate additional "end group" lines
          group_depth -= 1
          index_mod += 1
          row_index += 1
        end

        if q.group? # is this a group?
          group_name = q.code.tr(" ", "_")

          if q.repeatable?
            questions.row(row_index).push("begin repeat", group_name, q.code)
            repeat_depth += 1
          else
            questions.row(row_index).push("begin group", group_name, q.code)
          end

          # update counters
          group_depth += 1
        else # is this a question?
          # do we have an option set?
          if q.option_set_id.present?
            os = OptionSet.find(q.option_set_id)

            # include leading space to respect XLSForm format
            # question name should be followed by the option set name (if applicable) separated by a space
            # replace any spaces in the option set name with underscores to ensure the form is parsed correctly
            os_name = os.name.tr(" ", "_")
            os_already_logged = option_sets_used.include?(q.option_set_id)

            # log the option set to the spreadsheet if we haven't yet
            # ni = index for the option nodes loop
            # node = the current option node
            # TODO: support option set "levels" by creating a cascading sheet here
            unless os_already_logged
              os.option_nodes.each_with_index do |node, ni|
                if node.option.present?
                  choices
                    .row(ni + choices_index_mod)
                    .push(os_name, node.option.canonical_name, node.option.canonical_name)
                end
              end

              # increment the choices index by how many nodes there are, so we start at this row next time
              choices_index_mod += os.option_nodes.length

              option_sets_used.push(q.option_set_id)
            end
          end

          # convert question types
          qtype_converted = QTYPE_TO_XLS[q.qtype_name]

          type_to_push = "#{qtype_converted} #{os_name}"

          # Write the question row
          questions.row(row_index).push(type_to_push, q.code, q.name, q.required.to_s)
        end

        # if we have any relevant conditions, add them to the end of the row
        if q.display_conditions.any?
          questions.row(row_index).push(conditions_to_xls(q.display_conditions, q.display_if))
        end

        if q.constraints.any?
          q.constraints.each do |c|
            questions.row(row_index).push(conditions_to_xls(c.conditions, c.accept_if))
          end
        end
      end

      # Settings
      lang = @form.mission.setting.preferred_locales[0].to_s
      settings.row(1).push(@form.name, @form.id, @form.current_version.decorate.name, lang)

      # Write
      file = StringIO.new
      book.write(file)
      file.string
    end
    # rubocop:enable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Style/Next

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
        left_to_push = "${#{left_qing.code}_#{left_qing.full_dotted_rank}}"

        # prep right side of expression
        if dc.right_side_is_qing?
          right_qing = Questioning.find(dc.right_qing_id)
          right_to_push = "${#{right_qing.code}_#{right_qing.full_dotted_rank}}"
        elsif Float(dc.value, exception: false).nil? # it's not a number
          # to respect XLSform rules, surround with single quotes unless it's a number
          right_to_push = "'#{dc.value}'"
        else
          right_to_push = dc.value.to_s
        end

        op = ODK::ConditionDecorator::OP_XPATH[dc.op.to_sym]
        raise "Operation not found: #{dc.op}" if op.blank?

        # omit the concatenator on the last condition only
        relevant_to_push = if i + 1 == dc_length
                             "#{relevant_to_push}#{left_to_push} #{op} #{right_to_push}"
                           else
                             "#{relevant_to_push}#{left_to_push} #{op} #{right_to_push} #{concatenator} "
                           end
      end

      relevant_to_push
    end
  end
end
