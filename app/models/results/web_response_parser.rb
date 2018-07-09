# frozen_string_literal: true

module Results
  # Builds and saves response tree, with all blank answers, from a form object.
  class WebResponseParser

    PERMITTED_TOP_LEVEL_PARAMS = [:id, :questioning_id, :value].freeze
    # TODO: choices, media, time and date,
    OTHER_PERMITTED_PARAMS = [
      :option_node_id,
      "datetime_value(1i)",
      "datetime_value(2i)",
      "datetime_value(3i)",
      "datetime_value(4i)",
      "datetime_value(5i)",
      "datetime_value(6i)",
      "date_value(1i)",
      "date_value(2i)",
      "date_value(3i)",
      "time_value(1i)",
      "time_value(2i)",
      "time_value(3i)",
      "time_value(4i)",
      "time_value(5i)",
      "time_value(6i)",
      :media_object_id,
      {choices_attributes: %i[option_node_id checked]}
    ].freeze

    def initialize
    end

    # Expects ActionController::Parameters instance without required or permitted set
    def parse(data)
      root = new_node(data[:root], 0)
      add_children(data[:root][:children], root)
    end

    def add_children(children, parent_node)
      children.each_pair do |_k, v|
        next if ignore_node?(v)
        child = new_node(v, parent_node.children.length)
        parent_node.children << child
        add_children(v[:children], child) if v[:children]
      end
      parent_node
    end

    def new_node(data_node, new_rank)
      type = data_node[:type].constantize

      clean_params = data_node.slice(*PERMITTED_TOP_LEVEL_PARAMS).permit(
        [].concat(PERMITTED_TOP_LEVEL_PARAMS, OTHER_PERMITTED_PARAMS)
      )

      type.new(clean_params.merge(new_rank: new_rank))
    end

    def ignore_node?(data_node)
      data_node[:relevant] == "false" || data_node[:_destroy] == "true"
    end
  end
end
