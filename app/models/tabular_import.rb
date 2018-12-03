# frozen_string_literal: true

# For importing tabular data (CSV, XLSX, etc.)
class TabularImport
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Model
  extend ActiveModel::Naming
end
