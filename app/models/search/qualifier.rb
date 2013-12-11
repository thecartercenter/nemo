class Search::Qualifier

  attr_reader :name, :col, :type, :pattern, :default, :validator, :assoc

  # name  - the name of the qualifier (required, underscored)
  # type - qualifier type (optional, defaults to 'regular')
  # pattern - a regexp that will match the qualifier text
  # col - the database column being compared against (required unless :validator defined)
  # default - whether this qualifier should be assumed for terms with no qualifier (defaults to false)
  # validator - a lambda that accepts a MatchData object and returns whether the given string should be accepted as a valid qualifier
  def initialize(attribs)
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    @default ||= false
    @assoc = Array.wrap(@assoc)
    @subst ||= {}
    @type ||= :regular
  end

  def op_valid?(op)
    case type
    when :regular, :text then %w(= !=).include?(op)
    when :indexed then op == '='
    else true
    end
  end

  # for a regexp qualifier, checks if the given chunk matches
  def matches(chunk)
    return false unless regexp?
    # do a regexp match and save match data
    # then check the validator if given
    (md = pattern.match(chunk)) && (validator.nil? || validator.call(md))
  end

  # whether multiple ANDed terms are allowed for this qualifier
  def and_allowed?
    type == :text || type == :indexed
  end

  def default?
    default
  end

  def regexp?
    pattern.present?
  end
end