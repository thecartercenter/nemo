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
      attrs = {
        questioning_id: data_node[:questioning_id],
        new_rank: new_rank
      }
      attrs[:value] = data_node[:value] if type == Answer
      type.new(attrs)
    end

    def ignore_node?(data_node)
      !data_node[:relevant] || data_node[:_destroy]
    end
  end
end
