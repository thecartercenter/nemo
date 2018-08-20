# frozen_string_literal: true

module Results
  # View methods for rendering hierarchical response form
  class ResponseFormContext
    attr_reader :path, :options

    def initialize(path: [], **options)
      @path = path
      @options = options
    end

    def read_only?
      options[:read_only] == true
    end

    def add(*items)
      self.class.new(path: path + items, **options)
    end

    def full_path
      if path.present?
        path.zip(["children"] * (path.length - 1)).flatten.compact
      else
        []
      end
    end

    def input_name(*names)
      "response[root]" + (full_path + names).map { |item| "[#{item}]" }.join
    end

    def input_id(*names)
      "response_root_" + (full_path + names).join("_")
    end

    # Dash separated list of indices leading to this node, e.g. "0-2-1-1-0"
    # Used for uniquely identifying DOM elements.
    def id
      path.join("-")
    end

    # Find this context's path in the given response
    # Returns an answer node
    def find(response)
      find_node(response.root_node, path.dup)
    end

    private

    def find_node(node, indices)
      if indices.empty?
        node
      else
        index = indices.shift
        index = 0 if index == "__INDEX__"
        find_node(node.children[index], indices)
      end
    end
  end
end
