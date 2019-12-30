# frozen_string_literal: true

module ActiveModel
  module Translation
    include ActiveModel::Naming

    # Returns the +i18n_scope+ for the class. Overwriting so that all model translations are in :activerecord
    def i18n_scope
      :activerecord
    end
  end
end
