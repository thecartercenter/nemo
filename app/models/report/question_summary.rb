# frozen_string_literal: true

# models a summary of the answers for a question on a form
class Report::QuestionSummary
  # the questioning we're summarizing
  attr_reader :questioning

  # array containing the individual items of information in the summary
  attr_reader :items

  # the column headers, if any
  attr_reader :headers

  # the number of null answers we encountered
  attr_reader :null_count

  attr_reader :display_type, :overall_header

  delegate :reference, to: :questioning

  def initialize(attribs)
    # save attribs
    attribs.each { |k, v| instance_variable_set("@#{k}", v) }
  end

  delegate :qtype, to: :questioning

  # A summary is empty if it has no items, or if all items are zero.
  def empty?
    items.empty? || items.all?(&:zero?)
  end

  # gets a set of objects that allow this summary to be compared to others for clustering
  def signature
    [display_type, questioning.option_set, headers]
  end

  def as_json(options = {})
    h = super(options)
    h[:questioning] = questioning.as_json(
      only: %i[id rank],
      methods: %i[code name]
    )
    h[:items] = items
    h[:null_count] = null_count
    h
  end
end
