# frozen_string_literal: true

# For importing OptionSets from spreadsheet.
class OptionSetImportsController < TabularImportsController
  def new
    authorize!(:create, OptionSets::Import)
    build_object
  end

  def template
    # TODO: make template
    NotImplementedError
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
