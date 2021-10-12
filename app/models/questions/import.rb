# frozen_string_literal: true

module Questions
  # Imports Questions from a spreadsheet.
  class Import < TabularImport
    attr_accessor :questions, :lang_column

    delegate :mission_config, to: :question

    # The column where the translations start
    TRANSLATION_COLUMN = 3

    def initialize(*args)
      super
      self.questions = []
    end

    protected

    def process_data
      languages, rows = cleaner.clean
      add_run_errors(cleaner.errors)
      return if failed?

      rows.each_with_index { |row, row_idx| process_row(row, row_idx + 2, languages) }
    end

    private

    def cleaner
      @cleaner ||= ImportDataCleaner.new(sheet)
    end

    def process_row(row, row_idx, languages)
      return unless code_presence?(row[0], row_idx)

      params = {
        code: row[0],
        qtype_name: qtype_name(row[1], row_idx),
        mission_id: mission_id,
        name_translations: translations_json(row, TRANSLATION_COLUMN, languages),
        hint_translations: translations_json(row, TRANSLATION_COLUMN + 1, languages)
      }

      params[:option_set_id] = option_set_id(row[2], row_idx) if row[2].present?

      question = Question.create(params)
      questions << question
      copy_validation_errors_for_row(row_idx, question.errors) unless question.valid?
    end

    def code_presence?(code, row_idx)
      if code.blank?
        add_run_error(I18n.t(
          "operation.row_error",
          row: row_idx,
          error: I18n.t("activerecord.errors.models.question.code")
        ))
        false
      else
        true
      end
    end

    def option_set_id(name, row_idx)
      os = OptionSet.find_by(name: name)
      if os.nil?
        add_run_error(I18n.t(
          "operation.row_error",
          row: row_idx,
          error: I18n.t("activerecord.errors.models.question.option_set")
        ))
      else
        os.id
      end
    end

    def qtype_name(name, row_idx)
      return nil if name.blank?
      qtype = QuestionType[name.downcase]
      if qtype.nil?
        add_run_error(I18n.t(
          "operation.row_error",
          row: row_idx,
          error: I18n.t("activerecord.errors.models.question.qtype_unrecognized")
        ))
      else
        qtype.name
      end
    end

    def translations_json(row, start_col, languages)
      translation_json = {}
      col = start_col
      languages.each do |l|
        translation_json[l.to_sym] = row[col]
        # question name column translations alternates with hint
        col += 2
      end
      translation_json
    end

    def transaction
      if Rails.env.test? && ENV["NO_TRANSACTION_IN_IMPORT"]
        yield
      else
        Question.transaction { yield }
      end
    end
  end
end
