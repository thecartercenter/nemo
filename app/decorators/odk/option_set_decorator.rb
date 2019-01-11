# frozen_string_literal: true

module Odk
  # Decorates OptionSets for ODK rendering.
  class OptionSetDecorator < BaseDecorator
    delegate_all

    def odk_code
      CodeMapper.instance.code_for_item(object)
    end

    # Returns <text> tags for all options.
    def translation_tags(lang)
      tags = preordered_option_nodes.map do |node|
        content_tag(:text, id: Odk::CodeMapper.instance.code_for_item(node)) do
          content_tag(:value) do
            node.option.name(lang, strict: false)
          end
        end
      end
      tags.reduce(&:concat)
    end
  end
end
