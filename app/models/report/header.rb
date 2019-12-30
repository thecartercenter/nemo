# frozen_string_literal: true

# models a row/column of headers
class Report::Header
  attr_accessor :cells, :title

  def initialize(params)
    @cells = params[:cells].collect { |c| Report::HeaderCell.new(c) }
    @title = params[:title]
  end

  # looks for a header cell with a matching key and returns its index; returns nil if not found
  def find_key_idx(key)
    @cells.index { |c| c.key == key }
  end

  def collect(&block)
    @cells.collect(&block)
  end

  def size
    @cells.size
  end

  def as_json(_options = {})
    {title: title, cells: cells}
  end
end
