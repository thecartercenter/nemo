class Search < ActiveRecord::Base
  def self.canonicalize(query)
    query
  end
  
  # if query is empty, returns a new unsaved search
  # otherwise, finds or creates a search based on the given class_name and query
  def self.find_or_create(params)
    if params[:query].blank?
      new(params)
    else
      find_or_create_by_class_name_and_query(params[:class_name], params[:query])
    end
  end
  
  def self.find_or_create_canonicalized(query)
    find_or_create_by_query(canonicalize(query))
  end
  
  def conditions
    # get sql fragment for each term
    tokens.collect{|t| t.sql}.join(" ")
  end
  
  def eager
    tokens.collect{|t| t.eager}.flatten.uniq
  end
  
  def examples
    klass.search_examples
  end
  
  def klass
    @klass ||= Kernel.const_get(class_name)
  end
  
  def tokens
    parse unless defined?(@tokens)
    @tokens
  end
    
  protected
    def parse
      if query.blank?
        @tokens = []
        return
      end
      
      # split query up into tokens (quoted strings, or individual words, 
      # separated by spaces or commas, with or without a qualifier)
      tokenlist = query.scan(/((\w+:)?("([^\s]+?\s?)+?"|[^\s,]+))/)
    
      # add booleans and clean up
      s2 = "or"
      finaltokenlist = []
      tokenlist.each do |s1|
        # remove quotes because they are used for tokenizing, not content
        s1 = s1[0].gsub("\"","")
      
        # get rid of leading/trailing punctuation and other chars
        s1 = s1.gsub(/(^[^A-Za-z0-9\/]+|[^A-Za-z0-9\/]+$)/, "")
      
        # if the token is now empty,skip it
        if s1 == ""
          next
        end
      
        # if this pair of words already part of a boolean expression, don't insert an "and", otherwise default to "and"
        if %w[and or not].include?(s1) || %w[and or not].include?(s2)
          s2 = s1
          finaltokenlist << s1
        else
          s2 = s1
          finaltokenlist << "and"
          finaltokenlist << s1
        end
      end
      @tokens = finaltokenlist.collect{|s| SearchToken.new(s, klass)}
    end
end
