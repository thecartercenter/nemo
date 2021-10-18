# frozen_string_literal: true

module Questions
  # Exports questions with translations to csv
  class Export
    def initialize(questions, locales)
      @questions = questions
      @columns = ["Code", "QType", "Option Set Name"]
      @locales = locales

      @locales.each do |l|
        @columns << "Title[#{l}]" << "Hint[#{l}]"
      end
    end

    def to_csv(options = {})
      CSV.generate(**options) do |csv|
        csv << @columns
        row = []
        @questions.each do |q|
          row << q.code << q.qtype_name
          os_name = q.option_set_id.present? ? q.option_set&.name : ""
          row << os_name

          row = translations(q, row)

          csv << row
          row = []
        end
      end
    end

    private

    def translations(question, row)
      # no translations
      if question.name_translations.nil?
        row << q.name_or_none
        row << q.hint
        return
      end

      @locales.each do |l|
        title = question.name_translations.blank? ? question.name_or_none : question.name_translations[l.to_s]
        row << title
        hint = question.hint_translations.blank? ? "" : question.hint_translations[l.to_s]
        row << hint
      end
      row
    end
  end
end
