# frozen_string_literal: true

# For importing OptionSets from CSV/spreadsheet.
class OptionSetImportsController < TabularImportsController
  def template
    # TODO: make template
    NotImplementedError
  end

  protected

  def option_set_import_params
    params.require(:option_set_import).permit(:name)
  end

  def tabular_class
    OptionSetImport
  end

  def after_create_redirect_url
    option_sets_url
  end
end
