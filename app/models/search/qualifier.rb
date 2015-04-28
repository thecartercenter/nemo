class Search::Qualifier

  attr_reader :name, :col, :type, :pattern, :default, :validator, :assoc, :preprocessor

  ANDABLE_TYPES = %w(text indexed translated)

  # Looks up the qualifier for the given chunk in the given set.
  # Raises an error if not found.
  def self.find_in_set(set, chunk)
    qualifier = nil

    trans = translation_key(set)

    # also add the qualifier translations for english if the current locale is not english
    trans.merge!(translation_key(set, :en)) unless I18n.locale == :en

    # add a bunch of entries with accents removed
    normalized = {}
    trans.each do |k,v|
      k_normalized = ActiveSupport::Inflector.transliterate(k)
      normalized[k_normalized] = v if k != k_normalized
    end
    trans.merge!(normalized)

    # try looking up the chunk. this should now work even the user didn't put in the accents
    qualifier_name = trans[chunk].to_s

    # if qualifier_name is not nil, try to find the qualifier object
    unless qualifier_name.nil?
      qualifier = set.detect{|q| q.name == qualifier_name}
    end

    # if we haven't found a matching qualifier yet, look for any regexp style ones
    if qualifier.nil?
      set.find_all{|q| q.regexp?}.each do |q|
        # check against the regular expression and then against the validator (if defined)
        if q.matches(chunk)
          qualifier = q
          break
        end
      end
    end

    raise Search::ParseError.new(I18n.t("search.invalid_qualifier", chunk: chunk)) if qualifier.nil?

    qualifier
  end

  def self.translation_key(set, locale = nil)
    names = set.map(&:name)
    I18n.t("search_qualifiers", locale: locale || I18n.locale, default: {}).select{ |k,v| names.include?(k.to_s) }.invert
  end

  # name  - the name of the qualifier (required, underscored)
  # type - qualifier type (optional, defaults to 'regular' - which means exact equality is required for match)
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
    when :regular, :text, :translated then %w(= !=).include?(op)
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
    ANDABLE_TYPES.include?(type.to_s)
  end

  def default?
    default
  end

  def regexp?
    pattern.present?
  end
end
