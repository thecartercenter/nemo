# frozen_string_literal: true

# For importing OptionSets from spreadsheet.
class OptionSetImportsController < TabularImportsController
  def new
    authorize!(:create, OptionSets::Import)
    build_object
  end

  def template_multilevel
    authorize!(:create, OptionSets::Import)
    respond_to do |format|
      format.csv do
        render(csv: UserFacingCSV.generate do |csv|
          csv << %i[Kingdom Species]
          csv << %i[Animal Cat]
          csv << %i[Animal Dog]
          csv << %i[Plant Oak]
          csv << %i[Plant Tulip]
        end)
      end
    end
  end

  def template_translations
    authorize!(:create, OptionSets::Import)
    respond_to do |format|
      format.csv do
        render(csv: UserFacingCSV.generate do |csv|
          csv << %i(foo[en] foo[fr] Value)
          csv << %i[Cat Chat 1]
          csv << %i[Dog Chien 2]
        end)
      end
    end
  end

  protected

  def build_object
    @option_set_import = OptionSets::Import.new(mission: current_mission)
  end

  def option_sets_import_params
    params.require(:option_sets_import).permit(:name)
  end

  def tabular_class
    OptionSets::Import
  end

  def tabular_type_symbol
    :option_sets_import
  end

  def after_create_redirect_url
    option_sets_url
  end
end
