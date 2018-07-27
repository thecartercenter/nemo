# frozen_string_literal: true

module Results
  # View methods for rendering hierarchical response form
  class ResponseFormContext
    attr_reader :path

    def initialize(path = [])
      @path = path
    end

    def add(*items)
      self.class.new(path + items)
    end

    def input_name
      "response[root]" + path.map { |item| "[#{item}]" }.join
    end

    def id
      "response-root-" + path.join("-")
    end

    def indices
      path.reject { |item| item == :children }
    end

    # Find this context's path in the given response
    # Returns an answer node
    def find(response)
      find_node(response.root_node, indices)
    end

    private

    def find_node(node, indices)
      if indices.empty?
        node
      else
        index = indices.shift
        index = 0 if index == '__PLACEHOLDER__'
        find_node(node.children[index], indices)
      end
    end
  end
end
