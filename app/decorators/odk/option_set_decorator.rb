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
      tags.reduce(&:<<)
    end

    # Returns <instance> tags for each non-first level of the set. These are used for supporting
    # cascading behavior.
    def instances
      tags = (2..level_count).map do |level|
        content_tag(:instance, id: "#{odk_code}_level#{level}") do
          content_tag(:root, item_tags_for_level(level))
        end
      end
      tags.reduce(&:<<)
    end

    private

    def item_tags_for_level(level)
      tags = nodes_at_depth(level).map do |node|
        content_tag(:item) do
          # Use mapper directly here for efficiency.
          content_tag(:itextId, CodeMapper.instance.code_for_item(node)) <<
            content_tag(:parentId, CodeMapper.instance.code_for_item(node.parent))
        end
      end
      tags.reduce(&:<<)
    end

    def nodes_at_depth(depth)
      unless @nodes_by_depth
        @nodes_by_depth = {}
        preordered_option_nodes.each do |node|
          (@nodes_by_depth[node.depth] ||= []) << node
        end
      end
      @nodes_by_depth[depth]
    end
  end
end
