class Subindex
  attr_accessor(:page)
  
  # finds/creates a subindex for the given class name, and then sets the page number
  def self.find_and_update(session, user, class_name, page)
    si = find_or_create(session, user, class_name)
    si.page = page if page
    si
  end
  
  # finds or creates a subindex for the given class_name
  def self.find_or_create(session, user, class_name)
    session[:subindexes] ||= {}
    session[:subindexes][class_name.underscore.to_sym] ||= new(class_name, user)
  end
  
  def self.clear_all(session)
    session.delete(:subindexes)
  end
  
  def initialize(class_name, user)
    @class_name = class_name
    @user = user
    @page = 1
    reset_search
  end
  
  def params
    cond = []
    # get any permission conditions
    cond << Permission.select_conditions(:user => @user, :controller => @class_name.pluralize.underscore, :action => "index")
    # get search conditions
    cond << (@search ? ((sc = @search.conditions).blank? ? "1" : sc) : "1")
    # get eager associations
    eager = klass.default_eager + (@search ? @search.eager : [])
    # build and return params
    {:page => @page, :conditions => cond.collect{|c| "(#{c})"}.join(" and "), :include => eager}
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
    @search = Search.find_or_create(:class_name => @class_name)
  end
  
  def klass
    @klass ||= Kernel.const_get(@class_name)
  end
end