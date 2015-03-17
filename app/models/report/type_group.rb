# models a group of summary clusters for a standard form report.
# each group contains a set of types, e.g. categorical questions or numerical questions
class Report::TypeGroup
  # the type of group this is
  attr_reader :type_set, :clusters, :max_header_count, :summaries

  # each TypeGroup contains a set of types. this is them, in the order they'll be displayed.
  TYPE_SETS = ActiveSupport::OrderedHash[
    'categorical' => %w(select_one select_multiple),
    'numbers' => %w(integer decimal),
    'dates' => %w(date),
    'times' => %w(time datetime),
    'short_text' => %w(text),
    'long_text' => %w(long_text)
  ]

  # generates a set of groups for the given summaries and options
  # summaries are given in no particular order
  # options[:order] - either number or type
  def self.generate(summaries, options)
    # if order is by number, then just go for it
    case options[:question_order]
    when 'number'
      # return one big group
      [new(:type_set => 'all', :summaries => summaries)]

    # else if by type
    when 'type'
      # first, separate summaries by type set
      summaries_by_type_set = ActiveSupport::OrderedHash[*TYPE_SETS.each_key.map{|type_set| [type_set, []]}.flatten(1)]
      summaries.each do |s|
        summaries_by_type_set[types_to_type_sets[s.qtype.name]] << s
      end

      # generate each group
      summaries_by_type_set.map{|type_set, summaries| summaries.empty? ? nil : new(:type_set => type_set, :summaries => summaries)}.compact
    else
      raise 'no question order specified'
    end
  end

  # generates a hash of question types to type sets (reverse of the TYPE_SETS hash)
  def self.types_to_type_sets
    return @@types_to_type_sets if defined?(@@types_to_type_sets)
    @@types_to_type_sets = {}
    TYPE_SETS.each do |type_set, types|
      types.each do |t|
        @@types_to_type_sets[t] = type_set
      end
    end
    @@types_to_type_sets
  end

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    # sort appropriately
    sort_summaries

    find_max_header_count

    # generate clusters
    @clusters = Report::SummaryCluster.generate(@summaries)
  end

  # sorts summaries in this group depending on the group's type set
  def sort_summaries
    if type_set == 'categorical'
      # the categorical group should be sorted by option set name, then rank
      @summaries.sort_by!{|s| [s.questioning.option_set.name, s.questioning.rank]}

    else
      # else just sort by rank
      @summaries.sort_by!{|s| s.questioning.rank}
    end
  end

  # looks through all summaries and gets the max number of headers over all of them
  # this is useful in computing how many columns to put in a table
  # min should be one
  def find_max_header_count
    @max_header_count = (@summaries.map{|s| s.headers.try(:size) || 0} + [1]).max
  end

  def as_json(options = {})
    super(:only => [:type_set, :clusters, :max_header_count])
  end
end
