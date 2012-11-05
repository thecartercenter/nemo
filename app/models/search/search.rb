class Search::Search < ActiveRecord::Base
  # finds or creates a search based on the given class_name and str
  def self.find_or_create(params)
    find_or_create_by_class_name_and_str(params[:class_name], params[:str])
  end

  # parses the search string
  def parse
    @parser = Search::Parser.new(self)
    @parser.parse
  end

  # applies this search to the given relation
  def apply(relation)
    parse unless @parser
    # apply the needed associations
    relation = relation.joins(Report::Join.list_to_sql(@parser.assoc))
    # apply the conditions
    relation.where(@parser.sql)
  end
  
  def examples
    klass.search_examples
  end
  
  def klass
    @klass ||= Kernel.const_get(class_name)
  end
end