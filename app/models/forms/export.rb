# frozen_string_literal: true

module Forms
  # Exports a form to a human readable format for science!
  class Export
    COLUMNS = %w[
      Level Type Code Prompt Required? Repeatable? SkipLogic Constraints
      DisplayLogic DisplayConditions Default Hidden
    ].freeze

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
      # Repeat groups with nested "begin/end repeat" and "begin/end group" lines
      # skip logic with formatted info in "relevant" column using ${name} = ... syntax

      book = Spreadsheet::Workbook.new

      # Create sheets
      questions = book.create_worksheet(name: "survey")
      choices = book.create_worksheet(name: "choices")
      settings = book.create_worksheet(name: "settings")

      # Write sheet headings at row index 0
      questions.row(0).push("type", "name", "label", "required", "relevant")
      choices.row(0).push("list_name", "name", "label")
      settings.row(0).push("form_title", "form_id", "version", "default_language")

      group_depth = 1 # assume base level
      repeat_depth = 1
      index_mod = 1 # start at row index 1
      choices_index_mod = 1

      @form.preordered_items.each_with_index do |q, i|
        if q.group?
          if q.repeatable?
            questions.row(i + index_mod).push("begin repeat", q.code)
            repeat_depth += 1
          else
            questions.row(i + index_mod).push("begin group", q.code)
          end

          # update counters
          group_depth += 1
        else
          # did a group just end?
          # if so, the qing's depth will be smaller than the depth counter
          if q.ancestry_depth < group_depth
            # are we in a repeat group?
            # we don't want to end the repeat if we are ending a nested non-repeat group within a repeat
            # e.g., if group depth is deeper than repeat depth
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

          type_to_push = "#{q.qtype_name}#{os_name}"
          code_to_push = "#{q.full_dotted_rank}_#{q.code}"

          # Write the question row
          questions.row(i + index_mod).push(type_to_push, code_to_push, q.name, q.required.to_s, "TODO")
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
  end
end
