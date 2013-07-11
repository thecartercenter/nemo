class Search::Qualifier
  
  # required params - :name, :col
  def initialize(params)
    @params = params
    
    # by default, qualifier is not default-searched
    @params[:default] ||= false
    
    # by default, the associations are nil
    @params[:assoc] ||= nil
    
    # by default, search has to match exactly
    @params[:partials] ||= false
    
    # by default, there are no substitutions
    @params[:subst] ||= {}
  end
  
  def op_valid?(op)
    true # don't think this is necessary for now
  end
  
  def method_missing(m)
    if @params.keys.include?(m)
      @params[m.to_sym]
    elsif m.to_s.match(/(\w+)\?/) && @params.keys.include?(m = $1.to_sym)
      @params[m]
    else
      super
    end
  end
end