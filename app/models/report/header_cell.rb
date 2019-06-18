# frozen_string_literal: true

# models a single cell in a header
class Report::HeaderCell
  attr_accessor :name, :sort_value, :key

  def initialize(params)
    @name = params[:name]
    @sort_value = params[:sort_value] || @name
    @key = params[:key] || @name
  end

  def as_json(_options = {})
    {name: name, sort_value: sort_value, key: key}
  end
end
