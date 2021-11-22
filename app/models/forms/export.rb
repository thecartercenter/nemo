# frozen_string_literal: true

module Forms
  # Exports a form to a human readable format for science
  class Export
    def initialize(form)
      @form = form
      @columns = %w[Level Type Code Prompt Required? Repeatable? DisplayLogic Default Hidden]
    end

# display conditions, skip logic, constraints require some decorators
    def to_csv
      CSV.generate do |csv|
        csv << @columns
        qings = @form.questionings
        qings.each do |q|
          decorated_qing = QuestioningDecorator.decorate(q)
          # puts decorated_qing.skip_rule_targets
          csv << [
            q.full_dotted_rank, q.qtype_name, q.code, q.name,
            q.required, q.repeatable?, q.display_if, q.default, q.hidden
          ]
        end
      end
    end
  end
end
