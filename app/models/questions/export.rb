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
        @questions.each do |q|
          row = []
          row << q.code << q.qtype_name
          os_name = q.option_set_id.present? ? q.option_set&.name : ""
          row << os_name
          row.concat(translations(q))
          csv << row
        end
      end
    end

    private

    def build_name_and_hint(question)
      translations = []
      @locales.each do |l|
        title = question.name_translations.blank? ? question.name_or_none : question.name_translations[l.to_s]
        translations << title
        hint = question.hint_translations.blank? ? "" : question.hint_translations[l.to_s]
        translations << hint
      end
      translations
    end

    def translations(question)
      translations = []
      # no translations
      if question.name_translations.nil?
        translations << q.name_or_none
        translations << q.hint
        return translations
      end
      translations.concat(build_name_and_hint(question))
    end
  end
end
