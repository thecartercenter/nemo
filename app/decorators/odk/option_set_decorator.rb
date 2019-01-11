# frozen_string_literal: true

module Odk
  # Decorates OptionSets for ODK rendering.
  class OptionSetDecorator < BaseDecorator
    delegate_all

    def odk_code
      CodeMapper.instance.code_for_item(object)
    end
  end
end
