# frozen_string_literal: true

module Results
  # Builds and saves response tree, with all blank answers, from a form object.
  class WebResponseParser
    def initialize
    end

    def parse(data)
      root_questioning_id = data[:root][:questioning_id]
      root = new_node(data[:root], 0)
      add_children(data[:root][:children], root)
    end

    def add_children(children, parent_node)
      children.keys.each do |k|
        parent_node.children << new_node(children[k], k)
      end
      parent_node
    end

    def new_node(data_node, new_rank)
      type = data_node[:type].constantize
      type.new(
        questioning_id: data_node[:questioning_id],
        new_rank: new_rank
      )
    end
  end
end
