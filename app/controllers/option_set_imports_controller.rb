# frozen_string_literal: true

# For importing OptionSets from CSV/spreadsheet.
class OptionSetImportsController < TabularImportsController

  load_and_authorize_resource

  def tabular_class
    OptionSetImport
  end

  def tabular_type_symbol
    :option_set_import
  end

  def after_create_redirect_url
    option_set_url
  end

  def template
    # TODO: make template
    NotImplementedError
  end
end
