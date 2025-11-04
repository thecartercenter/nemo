# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
module Forms
  # Exports a form to a human-readable format for science!
  class Export # rubocop:disable Metrics/ClassLength
    include LanguageHelper

    COLUMNS = %w[
      Level Type Code Prompt Required? Repeatable? SkipLogic Constraints
      DisplayLogic DisplayConditions Default Hidden
    ].freeze

    QTYPE_TO_XLS = {
      # direct conversions
      "datetime" => "dateTime",

      # conversions with added "appearance" column
      # https://xlsform.org/en/#appearance
      "long_text" => "text", # "multiline"
      "annotated_image" => "image", # "annotate"
      "counter" => "integer", # "counter"
      "sketch" => "image", # "draw"
      "signature" => "image", # "signature"
      "location" => "geopoint", # "placement-map"

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
      "integer" => "integer"

      # Note: XLSForm qtypes not supported in NEMO:
      #   range, geotrace, geoshape, note, file, select_one_from_file, select_multiple_from_file,
      #   background-audio, calculate, acknowledge, hidden, xml-external
    }.freeze

    QTYPE_TO_APPEARANCE = {
      "long_text" => "multiline",
      "annotated_image" => "annotate",
      "counter" => "counter",
      "sketch" => "draw",
      "signature" => "signature",
      "location" => "placement-map"
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
      questions.row(0).push(
        "type", *local_headers("label", locales), *local_headers("hint", locales),
        "name", "required", "repeat_count", "appearance", "relevant", "default", "choice_filter",
        "constraint", *local_headers("constraint_message", locales),
        *local_headers("image", locales), *local_headers("audio", locales), *local_headers("video", locales)
      )

      # array for tracking nested groups.
      # push :group when a regular group is encountered, :repeat if repeat group.
      # when a group ends, we check .last, write "end group" or "end repeat" ,and then pop the last item out.
      # length of this array = current group depth
      group_tracker = []

      # array for tracking the option sets used by a form.
      # is later used by the method "options_to_xls" below to write the "choices" tab of the XLSForm.
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
        # if so, the qing's ancestry_depth will be smaller than the length of
        # the group tracker array (plus 1, because base ancestry_depth is 1)
        while group_tracker.length + 1 > q.ancestry_depth
          ended_group_type = group_tracker.pop
          if ended_group_type == :repeat
            questions.row(row_index).push("end repeat")
          elsif ended_group_type == :repeat_with_item_name
            # end both the repeat group and the inner group that carries the repeat_item_name
            # we need an extra increment on the index_mod due to the extra end group line
            questions.row(row_index).push("end group")
            questions.row(row_index + 1).push("end repeat")
            index_mod += 1
            row_index += 1
          else
            # end the group
            questions.row(row_index).push("end group")
          end

          # update counters to accommodate additional "end group" lines
          index_mod += 1
          row_index += 1
        end

        if q.group? # is this a group?
          # write begin group line and update group_tracker array
          if q.repeatable?
            questions.row(row_index).push("begin repeat")

            # Check for repeat item name
            if q.group_item_name.present?
              # If so, create an inner group here,
              # which should have the labels as defined in group_item_name_translations
              questions.row(row_index + 1).push("begin group")

              # write translated group item names on the inner group row
              locales.each do |locale|
                # Any instance of "$..." indicates that the user may be referring to another question.
                # However, XLSForm requires a syntax of "${...}" to refer to questions.
                # Use regex to make this syntax change.
                name = q.group_item_name_translations&.dig(locale.to_s)&.gsub(/\$(#{Question::CODE_FORMAT})/, "${\\1}")
                questions.row(row_index + 1).push(name)
              end
              # skip unused hint rows for inner group (length varies based on number of locales)
              locales.length.times { questions.row(row_index + 1).push("") }
              # push a name for the inner group (required for ODK)
              questions.row(row_index + 1).push("#{vanillify(q.code)}_item")

              # increment index_mod to account for the extra "begin group" line
              index_mod += 1

              # push a new type of group to the group tracker that will push end group / end repeat when it ends
              group_tracker.push(:repeat_with_item_name)
            else
              group_tracker.push(:repeat)
            end

            # Check for repeat count limit
            if q.repeat_count_qing_id.present?
              repeat_count_qing = Questioning.find(q.repeat_count_qing_id)
              repeat_count_to_push = "${#{repeat_count_qing.code}}"
            end
          else
            questions.row(row_index).push("begin group")
            group_tracker.push(:group)

            # In non-repeat groups, this field is unused
            repeat_count_to_push = ""
          end

          # write translated labels
          locales.each do |locale|
            questions.row(row_index).push(q.group_name_translations&.dig(locale.to_s))
          end

          # write translated hints
          locales.each do |locale| # rubocop:disable Style/CombinableLoops
            questions.row(row_index).push(q.group_hint_translations&.dig(locale.to_s))
          end

          # write group name
          questions.row(row_index).push(vanillify(q.code))

          # check and write repeat_count and "show on one screen" appearance
          # (add an empty string to skip the unused "required" column)
          appearance_to_push = ODK::DecoratorFactory.decorate(q).one_screen_appropriate? ? "field-list" : ""
          questions.row(row_index).push("", repeat_count_to_push, appearance_to_push)
        else # is this a question?
          # convert question types to ODK style
          qtype_converted = QTYPE_TO_XLS[q.qtype_name]
          appearance_to_push = QTYPE_TO_APPEARANCE[q.qtype_name] || ""

          # if we have any relevant conditions or constraints, save them now
          conditions_to_push = conditions_to_xls(q.display_conditions, q.display_if)

          # declare constraint arrays
          constraints_to_push = []
          constraint_msg_to_push = Array.new(locales.length, [])

          # obtain default response values, or else an empty string
          # if preload last saved value is checked, indicate this using XLSForm format
          # https://docs.getodk.org/form-logic/#values-from-the-last-saved-record
          default_to_push = if q.preload_last_saved
                              "${last-saved##{q.code}}"
                            else
                              q.default || ""
                            end

          # obtain media prompt content type and filename, if any
          # column order = image, audio, video
          # uploaded media will be one of these types; the other columns should be filled with an empty string
          # NEMO doesn't translate these attachments, so repeat the filename in each language
          media_prompt_to_push = Array.new(3 * locales.count, "")
          case q.media_prompt.content_type&.split("/")&.first
          when "image"
            locales.count.times do |n|
              media_prompt_to_push[(0 * locales.count) + n] = q.media_prompt.filename.to_s
            end
          when "audio"
            locales.count.times do |n|
              media_prompt_to_push[(1 * locales.count) + n] = q.media_prompt.filename.to_s
            end
          when "video"
            locales.count.times do |n|
              media_prompt_to_push[(2 * locales.count) + n] = q.media_prompt.filename.to_s
            end
          end

          # this is not a (repeat) group, so repeat_count is unused
          repeat_count_to_push = ""

          q.constraints.each do |c|
            constraints_to_push.push("(#{conditions_to_xls(c.conditions, c.accept_if)})")

            # Write translated constraint message columns ("rejection_msg" in NEMO)
            # https://xlsform.org/en/#constraint-message
            #
            # NEMO allows multiple constraint messages for each rule, whereas XLSForm only supports one message per row.
            # Thus, if there are multiple constraints or rules for this question,
            # combine all provided messages into one string (per locale)
            locales.each_with_index do |locale, locale_index|
              # Attempt to get a message for that constraint for that language
              # (may be nil if a translation is not provided)
              constraint_message = c.rejection_msg_translations&.dig(locale.to_s)
              constraint_msg_to_push[locale_index] += [constraint_message] if constraint_message.present?
            end
          end

          # convert arrays into concatenated strings in XLSForm format
          # constraint rules should be placed in parentheses and separated by "and"
          # constraint message will still be an array, but contain a string for each locale
          # https://docs.getodk.org/form-logic/#validating-and-restricting-responses
          constraints_to_push = constraints_to_push.join(" and ")
          constraint_msg_to_push = constraint_msg_to_push.map { |n| n.join("; ") }

          # if we have an option set, identify and save it so that we can add it to the choices sheet later.
          # then, write the question, splitting it into multiple questions if there are option set levels.
          choice_filter = ""
          if q.option_set_id.present?
            os = q.option_set
            option_sets_used.push(q.option_set_id)

            # include leading space to respect XLSForm format
            # question name should be followed by the option set name (if applicable) separated by a space
            # replace any spaces in the option set name with underscores to ensure the form is parsed correctly
            os_name = vanillify(os.name)

            # is the option set multilevel?
            if os.level_names.present?
              os.level_names.each_with_index do |level, l_index|
                level_name = unique_level_name(os_name, level.values[0])

                # Append level name to qtype
                type_to_push = "#{qtype_converted} #{level_name}"

                # Modify question name
                name_to_push = "#{q.code}_#{level_name}"

                # push a row for each level
                questions.row(row_index + l_index).push(type_to_push)

                # write translated labels
                locales.each do |locale|
                  questions.row(row_index + l_index).push(q.question.name_translations&.dig(locale.to_s))
                end

                # write translated hints
                locales.each do |locale| # rubocop:disable Style/CombinableLoops
                  questions.row(row_index + l_index).push(q.question.hint_translations&.dig(locale.to_s))
                end

                questions.row(row_index + l_index).push(name_to_push,
                  q.required.to_s, repeat_count_to_push, appearance_to_push, conditions_to_push, default_to_push, choice_filter, constraints_to_push, *constraint_msg_to_push, *media_prompt_to_push)

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

              # write translated labels
              locales.each do |locale|
                questions.row(row_index).push(q.question.name_translations&.dig(locale.to_s))
              end

              # write translated hints
              locales.each do |locale| # rubocop:disable Style/CombinableLoops
                questions.row(row_index).push(q.question.hint_translations&.dig(locale.to_s))
              end

              questions.row(row_index).push(q.code, q.required.to_s, repeat_count_to_push, appearance_to_push,
                conditions_to_push, default_to_push, choice_filter, constraints_to_push, *constraint_msg_to_push, *media_prompt_to_push)
            end
          else # no option set present
            # Write the question row as normal
            questions.row(row_index).push(qtype_converted)

            # write translated labels
            locales.each do |locale|
              questions.row(row_index).push(q.question.name_translations&.dig(locale.to_s))
            end

            # write translated hints
            locales.each do |locale| # rubocop:disable Style/CombinableLoops
              questions.row(row_index).push(q.question.hint_translations&.dig(locale.to_s))
            end

            questions.row(row_index).push(q.code, q.required.to_s, repeat_count_to_push, appearance_to_push,
              conditions_to_push, default_to_push, choice_filter, constraints_to_push, *constraint_msg_to_push, *media_prompt_to_push)
          end
        end

        # are we at the end of the form?
        if i == @form.preordered_items.size - 1
          row_index += 1

          # do we still have unclosed groups in the tracker array?
          # if so, close those groups from last to first.
          while group_tracker.present?
            ended_group_type = group_tracker.pop
            if ended_group_type == :repeat
              questions.row(row_index).push("end repeat")
            elsif ended_group_type == :repeat_with_item_name
              # end both the repeat group and the inner group that carries the repeat_item_name
              # we need an extra increment on the index_mod due to the extra end group line
              questions.row(row_index).push("end group")
              questions.row(row_index + 1).push("end repeat")
              index_mod += 1
              row_index += 1
            else
              # end the group
              questions.row(row_index).push("end group")
            end

            # update counters to accomodate additional "end group" lines
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
      settings.row(0).push("form_title", "form_id", "version", "default_language", "allow_choice_duplicates")

      lang = @form.mission.setting.preferred_locales[0].to_s
      version = if @form.current_version.present?
                  @form.current_version.decorate.name
                else
                  "1"
                end
      settings.row(1).push(@form.name, @form.id, version, lang, "yes")

      ## Style
      format = Spreadsheet::Format.new(
        color: :navy,
        weight: :bold,
        text_wrap: true
      )
      questions.row(0).default_format = format
      choices.row(0).default_format = format
      settings.row(0).default_format = format

      # Freeze header rows
      questions.freeze!(1, 0)
      choices.freeze!(1, 0)
      settings.freeze!(1, 0)

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

    # Given a header like `"label"`, return an array of localized headers like `["label::English (en)"]`
    def local_headers(header, locales)
      locales.map do |locale|
        "#{header}::#{language_name(locale)} (#{locale})"
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

          if node.level.present?
            # per XLSform style, option sets with levels need to have the
            # list_name replaced with the level name to distinguish each row.
            listname_to_push = unique_level_name(os.name, node.level_name)

            # Only attempt to access node ancestors if they exist
            if node.ancestry_depth > 1
              # Add a buffer of blank cells to accommodate columns used up by prior option sets
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
            header_row.push(unique_level_name(os.name, level.values[0]))

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

    # prepend option set name so that level names are unique
    # this avoids duplicate header errors
    def unique_level_name(os_name, level_name)
      "#{vanillify(os_name)}_#{vanillify(level_name)}"
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
