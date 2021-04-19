# frozen_string_literal: true

module ODK
  # Decorates OptionSets for ODK rendering.
  class OptionSetDecorator < BaseDecorator
    delegate_all

    EXTERNAL_CSV_METHOD_THRESHOLD = 300

    def external_csv?
      multilevel? && total_options > EXTERNAL_CSV_METHOD_THRESHOLD
    end

    def odk_code
      CodeMapper.instance.code_for_item(object)
    end

    # Returns <text> tags for options.
    def translation_tags(lang)
      tags = nodes_for_translation_tags.map do |node|
        content_tag(:text, id: ODK::CodeMapper.instance.code_for_item(node)) do
          content_tag(:value) do
            node.option.name(lang, fallbacks: true)
          end
        end
      end
      tags.reduce(&:<<)
    end

    # Returns <instance> for option sets that have dynamic calcs only
    # Only supports level 1 option sets
    def option_instances_for_dynamic_calcs
      content_tag(:instance, id: "#{odk_code}_numeric_values") do
        content_tag(:root) do
          first_level_option_nodes.map { |node| option_item(node) }.reduce(&:<<)
        end
      end
    end

    def option_item(node)
      content_tag(:item) do
        content_tag(:itextId, ODK::CodeMapper.instance.code_for_item(node)) <<
          content_tag(:numericValue, node.option.value)
      end
    end

    # Returns <instance> tags for each non-first level of the set. These are used for supporting
    # cascading behavior.
    def cascading_instances
      tags = (2..level_count).map do |depth|
        content_tag(:instance, id: instance_id_for_depth(depth)) do
          content_tag(:root, item_tags_for_depth(depth))
        end
      end
      tags.reduce(&:<<)
    end

    def instance_id_for_depth(depth)
      "#{odk_code}_level#{depth}"
    end

    private

    # Returns the OptionNodes that should be represented with translation tags.
    # If using external CSV method, this should just be the top level.
    def nodes_for_translation_tags
      # Don't use nodes_at_depth because that loads all options unnecessarily.
      external_csv? ? first_level_option_nodes : preordered_option_nodes
    end

    def item_tags_for_depth(level)
      tags = nodes_at_depth(level).map do |node|
        content_tag(:item) do
          # Use mapper directly here for efficiency.
          content_tag(:itextId, CodeMapper.instance.code_for_item(node)) <<
            content_tag(:parentId, CodeMapper.instance.code_for_item(node.parent))
        end
      end
      tags.reduce(&:<<)
    end

    # Gets all OptionNodes at given depth. Memoizes. Returns empty array if no nodes at that level.
    def nodes_at_depth(depth)
      unless @nodes_by_depth
        @nodes_by_depth = {}
        preordered_option_nodes.each do |node|
          (@nodes_by_depth[node.depth] ||= []) << node
        end
      end
      @nodes_by_depth[depth] || []
    end
  end
end
