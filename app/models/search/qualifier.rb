class Search::Qualifier
  
  attr_reader :name, :col, :default, :assoc, :partials, :subst, :fulltext, :extra_condition, :validator

  # name  - the name of the qualifier (required, underscored)
  # col - the database column being compared against (required)
  # default - whether this qualifier should be assumed for terms with no qualifier (defaults to false)
  # assoc - the associations needed if this qualifier is used (defaults to nil)
  # partials - whether partial LIKE matches are allowed (defaults to false)
  # subst - a hash of values to substitute when generating sql (e.g. 'yes' => 1, defaults to {})
  # fulltext - whether to use fulltext searching (defaults to false)
  # extra_condition - a lambda that accepts a MatchData object and returns a set of arguments to an SQL sanitizer, to be added to the query
  # validator - a lambda that accepts a MatchData object and returns whether the given string should be accepted as a valid qualifier
  def initialize(attribs)
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
    
    @default ||= false
    @assoc = Array.wrap(@assoc)
    @partials ||= false
    @subst ||= {}
    @fulltext ||= false
  end
  
  def op_valid?(op)
    # only '=' is valid for fulltext qualifiers
    !(fulltext? && op != '=')
  end

  # for a regexp qualifier, checks if the given chunk matches
  def matches(chunk)
    # do a regexp match and save match data
    # then check the validator if given
    (md = name.match(chunk)) && (validator.nil? || validator.call(md))
  end
  
  def default?
    default
  end

  def partials?
    partials
  end

  def fulltext?
    fulltext
  end

  def regexp?
    name.is_a?(Regexp)
  end
end