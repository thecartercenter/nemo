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
