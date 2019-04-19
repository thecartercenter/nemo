# frozen_string_literal: true

module Results
  # View methods for rendering hierarchical response form
  class ResponseFormContext
    attr_reader :path, :options, :visible_depth

    def initialize(path: [], visible_depth: 0, **options)
      @path = path
      @options = options
      @visible_depth = visible_depth
    end

    def read_only?
      options[:read_only] == true
    end

    def add(item, visible: true)
      self.class.new(path: path + [item], visible_depth: visible_depth + (visible ? 1 : 0), **options)
    end

    def index
      path.last
    end

    def depth
      path.size
    end

    def full_path
      if path.present?
        ["children"] + path.zip(["children"] * (depth - 1)).flatten.compact
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
    def path_str
      path.join("-")
    end
  end
end
