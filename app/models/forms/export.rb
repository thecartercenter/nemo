# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
module Forms
  # Exports a form to a human readable format for science!
  class Export # rubocop:disable Metrics/ClassLength
    include LanguageHelper

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

    # rubocop:disable Metrics/BlockLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Style/Next
    def to_xls
      book = Spreadsheet::Workbook.new

      # Create sheets
      questions = book.create_worksheet(name: "survey")
      choices = book.create_worksheet(name: "choices")
      settings = book.create_worksheet(name: "settings")

      # Get languages
      locales = @form.mission.setting.preferred_locales

      # Write sheet headings at row index 0
      questions.row(0).push("type")

      locales.each do |locale|
        questions.row(0).push("label::#{language_name(locale)} (#{locale})",
          "hint::#{language_name(locale)} (#{locale})")
      end

      questions.row(0).push("name", "required", "relevant", "choice_filter", "constraint")

      locales.each do |locale|
        questions.row(0).push("constraint message::#{language_name(locale)} (#{locale})")
      end

      settings.row(0).push("form_title", "form_id", "version", "default_language")

      group_depth = 1 # assume base level
      repeat_depth = 1
      option_sets_used = []

      # Define the below "index modifiers" which keep track of the line of the spreadsheet we are writing to.
      # The for loop below (tracked by index i) loops through the list of form items, and so the index does not
      # take into account rows that we need to write for when groups end.
      # In XLSForm, these are written to a row all to themselves.
      # This causes the index i to be de-synchronized with the row of the spreadsheet that we are writing to.
      # Hence, we push to the row (i + index_mod)
      index_mod = 1 # start at row index 1

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
          # write begin group line
          if q.repeatable?
            questions.row(row_index).push("begin repeat")
            repeat_depth += 1
          else
            questions.row(row_index).push("begin group")
          end

          # write translated label and hint columns
          locales.each do |locale|
            questions.row(row_index).push(q.group_name_translations&.dig(locale.to_s),
              q.group_hint_translations&.dig(locale.to_s))
          end

          # write group name
          questions.row(row_index).push(vanillify(q.code))

          # update counters
          group_depth += 1
        else # is this a question?
          # convert question types to ODK style
          qtype_converted = QTYPE_TO_XLS[q.qtype_name]

          # if we have any relevant conditions or constraints, save them now
          conditions_to_push = conditions_to_xls(q.display_conditions, q.display_if)

          constraints_to_push = ""
          constraint_msg_to_push = Array.new(locales.length, "")
          q.constraints.each_with_index do |c, c_index|
            # constraint rules should be placed in parentheses and separated by "and"
            # https://docs.getodk.org/form-logic/#validating-and-restricting-responses
            constraints_to_push += "(#{conditions_to_xls(c.conditions, c.accept_if)})"

            # add "and" unless we're at the end
            constraints_to_push += " and " unless c_index + 1 == q.constraints.length

            # Write translated constraint message columns ("rejection_msg" in NEMO)
            # https://xlsform.org/en/#constraint-message
            # NEMO allows multiple constraint messages for each rule, whereas XLSForm only supports one message per row.
            # Thus, if there are multiple constraints or rules for this question, combine all provided messages into one string (per locale), separated by a semicolon
            locales.each_with_index do |locale, locale_index|
              # Attempt to get a message for that constraint for that language (may be nil if a translation is not provided)
              constraint_message = c.rejection_msg_translations&.dig(locale.to_s)

              if constraint_message.present?
                constraint_msg_to_push[locale_index] += constraint_message
                # Add semicolon concatenator, unless at the end
                constraint_msg_to_push[locale_index] += "; " unless c_index + 1 == q.constraints.length
              end
            end
          end

          # if we have an option set, identify and save it so that we can add it to the choices sheet later.
          # then, write the question, splitting it into multiple questions if there are option set levels.
          os_name = ""
          choice_filter = ""
          if q.option_set_id.present?
            os = OptionSet.find(q.option_set_id)
            option_sets_used.push(q.option_set_id)

            # include leading space to respect XLSForm format
            # question name should be followed by the option set name (if applicable) separated by a space
            # replace any spaces in the option set name with underscores to ensure the form is parsed correctly
            os_name = vanillify(os.name)

            # is the option set multilevel?
            if os.level_names.present?
              os.level_names.each_with_index do |level, l_index|
                level_name = vanillify(level.values[0])

                # Append level name to qtype
                type_to_push = "#{qtype_converted} #{level_name}"

                # Modify question name
                name_to_push = "#{q.code}_#{level_name}"

                # push a row for each level
                questions.row(row_index + l_index).push(type_to_push)

                # write translated label and hint columns
                locales.each do |locale|
                  questions.row(row_index + l_index).push(q.question.name_translations&.dig(locale.to_s),
                    q.question.hint_translations&.dig(locale.to_s))
                end

                questions.row(row_index + l_index).push(name_to_push,
                  q.required.to_s, conditions_to_push, choice_filter, constraints_to_push)

                constraint_msg_to_push.each do |message|
                  questions.row(row_index + l_index).push(message)
                end

                # define the choice_filter cell for the following row, e.g, "state=${selected_state}"
                choice_filter = "#{level_name}=${#{name_to_push}}"
              end

              # increase index modifier by the number of levels so we start on the correct row next time
              index_mod += os.level_names.length - 1
            else # it's a single-level select question
              # Append option set name to qtype
              type_to_push = "#{qtype_converted} #{os_name}"

              # Write the question row
              questions.row(row_index).push(type_to_push)
              # write translated label and hint columns
              locales.each do |locale|
                questions.row(row_index).push(q.question.name_translations&.dig(locale.to_s),
                  q.question.hint_translations&.dig(locale.to_s))
              end
              questions.row(row_index).push(q.code, q.required.to_s,
                conditions_to_push, choice_filter, constraints_to_push)

              constraint_msg_to_push.each do |message|
                questions.row(row_index).push(message)
              end
            end
          else # no option set present
            # Write the question row as normal
            questions.row(row_index).push(qtype_converted)
            # write translated label and hint columns
            locales.each do |locale|
              questions.row(row_index).push(q.question.name_translations&.dig(locale.to_s),
                q.question.hint_translations&.dig(locale.to_s))
            end
            questions.row(row_index).push(q.code, q.required.to_s,
              conditions_to_push, choice_filter, constraints_to_push)

            constraint_msg_to_push.each do |message|
              questions.row(row_index).push(message)
            end
          end
        end

        # are we at the end of the form?
        if i == @form.preordered_items.size - 1
          row_index += 1

          # did one or more groups just end?
          # if so, the qing's depth will be smaller than the depth counter
          while group_depth > 1
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
        end
      end
      # end of giant @form loop

      ## Choices
      # return an array of option set data to write to the spreadsheet
      # only pass in unique option set IDs
      option_matrix = options_to_xls(option_sets_used.uniq, locales)

      # Loop through matrix array and write to "choices" tab of the XLSForm
      option_matrix.each_with_index do |option_row, row_index|
        option_row.each_with_index do |row_to_write, _column_index|
          choices.row(row_index).push(row_to_write)
        end
      end

      ## Settings
      lang = @form.mission.setting.preferred_locales[0].to_s
      version = if @form.current_version.present?
                  @form.current_version.decorate.name
                else
                  "1"
                end
      settings.row(1).push(@form.name, @form.id, version, lang)

      ## Write
      file = StringIO.new
      book.write(file)
      file.string
    end
    # rubocop:enable Metrics/BlockLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Style/Next

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
      return "" unless conditions.any?

      relevant_to_push = ""
      concatenator = true_if == "all_met" ? "and" : "or"

      # how many conditions?
      dc_length = conditions.length

      conditions.each_with_index do |dc, i|
        # prep left side of expression
        left_qing = Questioning.find(dc.left_qing_id)
        left_to_push = "${#{left_qing.code}}"

        # prep right side of expression
        # operation will vary based on what we are comparing to
        if dc.right_side_is_qing? # it's another question's value
          right_qing = Questioning.find(dc.right_qing_id)
          right_to_push = "${#{right_qing.code}}"
        elsif dc.option_node_id.present? # it's an option set choice
          right_node_value = OptionNode.find(dc.option_node_id).option.canonical_name
          right_to_push = "'#{right_node_value}'"
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

    # This function traverses the option nodes and outputs data to write to the options sheet
    # Include cascading levels as additional columns if they exist
    # option_sets = array of unique option set IDs used in the exported form
    # locales = list of possible translations
    # https://docs.getodk.org/form-logic/#filtering-options-in-select-questions
    def options_to_xls(option_sets, locales)
      # initialize option set matrix
      os_matrix = []

      # push header row column titles
      header_row = []
      header_row.push("list_name", "name")
      locales.each do |locale|
        header_row.push("label::#{language_name(locale)} (#{locale})")
      end

      column_counter = 0

      # for each unique option set in the list:
      # loop through the nodes and extract the options
      option_sets.each do |id|
        # get the option set from id
        os = OptionSet.find(id)

        # node = the current option node
        os.option_nodes.each do |node|
          level_to_push = [] # array to be filled with parent levels if needed
          listname_to_push = "" # name of the option set

          if node.level.present?
            # per XLSform style, option sets with levels need to have the
            # list_name replaced with the level name to distinguish each row.
            listname_to_push = node.level_name

            # Only attempt to access node ancestors if they exist
            if node.ancestry_depth > 1
              # Add a buffer of blank cells to accomodate columns used up by prior option sets
              column_counter.times { level_to_push.push("") }

              # Obtain array of all ancestor nodes (except for the root, which is nameless)
              level_to_push += vanillify(node.ancestors[1..].map(&:name))
            end
          else
            listname_to_push = os.name
          end

          if node.option.present? # rubocop:disable Style/Next
            option_row = []

            # remove extra chars and spaces
            listname_to_push = vanillify(listname_to_push)
            choicename_to_push = vanillify(node.option.canonical_name)

            option_row.push(listname_to_push, choicename_to_push)

            # push translated label columns
            locales.each do |locale|
              option_row.push(node.option.name_translations&.dig(locale.to_s))
            end

            option_row += level_to_push # append levels, if any, to rightmost columns
            os_matrix.push(option_row)
          end
        end

        # prep header row
        # omit last entry (lowest level)
        if os.level_names.present?
          os.level_names[0..-2].each do |level|
            header_row.push(vanillify(level.values[0]))

            # increment column counter
            column_counter += 1
          end
        end

        # push an empty array after each option set, translating to a row of space on the XLSform, for readability
        os_matrix.push([])
      end

      # return os_matrix with prepended header_row
      os_matrix.insert(0, header_row)
    end

    # recursively remove pesky characters and replace spaces with underscores
    # for XLSForm compatibility
    def vanillify(input)
      return "" if input.nil?

      if input.instance_of?(String)
        input.vanilla.tr(" ", "_")
      elsif input.instance_of?(Array)
        input.map { |n| n.vanilla.tr(" ", "_") }
      else
        raise "Unallowed type passed to vanillify: #{input.class}"
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength
