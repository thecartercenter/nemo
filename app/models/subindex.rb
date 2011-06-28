class Subindex
  attr_accessor(:page)
  
  # finds/creates a subindex for the given class name, and then sets the page number
  def self.find_and_update(session, class_name, page)
    si = find_or_create(session, class_name)
    si.page = page if page
    si
  end
  
  # finds or creates a subindex for the given class_name
  def self.find_or_create(session, class_name)
    session["#{class_name.underscore}_subindex".to_sym] ||= new(class_name)
  end
  
  def initialize(class_name)
    @class_name = class_name
    @page = 1
    reset_search
  end
  
  def params
    {:page => @page, :conditions => @search ? @search.conditions : "1"}
  end
  
  def search
    reset_search if @search.nil?
    @search
  end
  
  def search=(s)
    if @search != s
      @page = 1
      @search = s
    end
    reset_search if @search.nil?
  end
  
  def reset_search
    @search = Search.new(:class_name => @class_name)
  end
end