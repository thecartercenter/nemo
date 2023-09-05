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

    def to_xls
      book = Spreadsheet::Workbook.new

      # Create sheets
      questions = book.create_worksheet :name => "survey"
      choices = book.create_worksheet :name => "choices"
      settings = book.create_worksheet :name => "settings"

      # Write sheet headings at row index 0
      questions.row(0).push("type", "name", "label", "required", "relevant")
      choices.row(0).push("list_name", "name", "label")
      settings.row(0).push("form_title", "form_id", "version", "default_language")

      @form.preordered_items.each_with_index do |q, i|
        questions.row(i+1).push(q.qtype.name, q.code, q.name, q.required.to_s, "TODO")
      end

      # Choices TODO
      choices.row(1).push("yes_no", "yes", "YES")
      choices.row(2).push("yes_no", "no", "NO")

      # Settings
      settings.row(1).push(@form.name, @form.id, @form.updated_at.to_s, "English (en)")

      # Write
      file = StringIO.new
      book.write(file)
      file.string.html_safe
    end

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
  end
end
