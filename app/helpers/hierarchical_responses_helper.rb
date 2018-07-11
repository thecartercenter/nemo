# frozen_string_literal: true

# View helpers for rendering hierarchical response tree
module HierarchicalResponsesHelper
  def input_name(path)
    "response[root]" + path.map { |item| "[#{item}]" }.join
  end
end
