class Search::Search < ActiveRecord::Base
  has_many(:reports, :class_name => 'Report::Report', :foreign_key => 'filter_id', :inverse_of => :filter)

  attr_accessor :qualifiers

  # temporary measure to fix searching for reports
  attr_accessor :dont_group

  # parses the search string
  def parse
    @parser = Search::Parser.new(:search => self)
    @parser.parse
  end

  # expose the generated sql for testing purposes
  def sql
    parse unless @parser
    @parser.sql
  end

  # applies this search to the given relation
  def apply(rel)
    parse unless @parser

    # apply the needed associations
    rel = rel.joins(Report::Join.list_to_sql(@parser.assoc))
    
    # apply the conditions
    rel = rel.where(@parser.sql)
    
    # apply a group clause so that there are no duplicates due to the join
    rel = rel.group("`#{rel.table_name}`.id") unless dont_group

    rel
  end
end