# frozen_string_literal: true

# For importing Questions from spreadsheet.
class QuestionImportsController < TabularImportsController
  def new
    authorize!(:create, Questions::Import)
    build_object
  end

  def template
    authorize!(:create, Questions::Import)
    headers = %i(Code QType Option\ Set\ Name Title[en] Hint[en] Title[fr] Hint[fr])
    respond_to do |format|
      format.csv do
        render(csv: UserFacingCSV.generate { |csv| csv << headers })
      end
    end
  end

  protected

  def build_object
    @question_import = Questions::Import.new(mission: current_mission)
  end

  def questions_import_params
    []
  end

  def tabular_class
    Questions::Import
  end

  def tabular_type_symbol
    :questions_import
  end

  def after_create_redirect_url
    questions_url
  end
end
