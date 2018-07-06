# frozen_string_literal: true

module Results
  # Builds and saves response tree, with all blank answers, from a form object.
  class WebResponseParser
    def initialize

    end

    def parse(data)
      root = new_node(data[:root], 0)
      add_children(data[:root][:children], root)
    end

    def add_children(children, parent_node)
      children.each do |k, v|
        parent_node.children << new_node(v, k)
      end
      parent_node
    end

    def new_node(data_node, new_rank)
      type = data_node[:type].constantize
      attrs = {
        questioning_id: data_node[:questioning_id],
        new_rank: new_rank
      }
      attrs[:value] = data_node[:value] if type == Answer
      type.new(attrs)
    end
  end
end
