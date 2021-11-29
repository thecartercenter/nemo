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
        qings = @form.questionings
        prev = nil
        qings.each do |q|
          csv << row(q.parent) if include_repeat_group?(q, prev)
          csv << row(q)
          prev = q
        end
      end
    end

    private

    def include_repeat_group?(qing, prev)
      qing.parent.repeatable? && (qing.ancestry_depth != prev&.ancestry_depth)
    end

    def human_readable(klass, qing)
      plural_method = klass == Condition ? "display_conditions" : klass.model_name.plural
      qing.send(plural_method).map do |item|
        "#{klass}Decorator".constantize.decorate(item).human_readable
      end.join("|")
    end

    def row(qing)
      name = qing.respond_to?(:name) ? qing.name : "Repeat Group"
      [
        qing.full_dotted_rank, qing.qtype_name, qing.code, name,
        qing.required, qing.repeatable?, human_readable(SkipRule, qing),
        human_readable(Constraint, qing), qing.display_if, human_readable(Condition, qing),
        qing.default, qing.hidden
      ]
    end
  end
end
