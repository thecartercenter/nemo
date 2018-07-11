# frozen_string_literal: true

module Results
  # Builds and saves response tree, with all blank answers, from a form object.
  class WebResponseParser

    TOP_LEVEL_PARAMS = [
      :id,
      :questioning_id,
      :value,
      :option_node_id,
      :"datetime_value(1i)",
      :"datetime_value(2i)",
      :"datetime_value(3i)",
      :"datetime_value(4i)",
      :"datetime_value(5i)",
      :"datetime_value(6i)",
      :"date_value(1i)",
      :"date_value(2i)",
      :"date_value(3i)",
      :"time_value(1i)",
      :"time_value(2i)",
      :"time_value(3i)",
      :"time_value(4i)",
      :"time_value(5i)",
      :"time_value(6i)",
      :media_object_id,
      :choices_attributes
    ].freeze

    #TODO: fix? not quite working right
    PERMITTED_PARAMS = (TOP_LEVEL_PARAMS.dup - [:choices_attributes]).append(choices_attributes: %w[option_node_id checked])

    def initialize
    end

    # Expects ActionController::Parameters instance without required or permitted set
    def parse(data)
      root = new_node(data[:root], nil)
      add_children(data[:root][:children], root)
    end

    def add_children(children, parent_node)
      children.each_pair do |_k, v|
        next if ignore_node?(v)
        child = new_node(v, parent_node)
        parent_node.children << child
        add_children(v[:children], child) if v[:children]
      end
      parent_node
    end

    def new_node(data_node, parent)
      type = data_node[:type].constantize

      clean_params = data_node.slice(*TOP_LEVEL_PARAMS).permit(
        [].concat(PERMITTED_PARAMS)
      )
      rank_attributes = rank_attributes(parent)
      all_attrs = clean_params.merge(rank_attributes)
      type.new(all_attrs)
    end

    def ignore_node?(data_node)
      data_node[:relevant] == "false" || data_node[:_destroy] == "true"
    end

    # Rank will go away at end of answer refactor
    def rank_attributes(parent)
      {
        new_rank: parent.present? ? parent.children.length : 0,
        rank: parent.is_a?(AnswerSet) ? parent.children.length + 1 : 1
      }
    end
  end
end
