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
  end
end
