# models a single cell in a header
class Report::HeaderCell
  attr_accessor :name, :sort_value, :key

  def initialize(params)
    @name = params[:name]
    @sort_value = params[:sort_value] || @name
    @key = params[:key] || @name
  end
end