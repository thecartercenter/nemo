# frozen_string_literal: true

class Report::SummaryCollection
  attr_reader :subsets, :questionings

  # merges collections by concatenating summary arrays for each set of subsets with matching disagg_values
  def self.merge_all(collections, questionings)
    # start with an empty collection
    merged = new(questionings: questionings)

    # merge each of the given collections
    collections.each { |c| merged.merge(c) }

    # return
    merged
  end

  def initialize(attribs)
    # save attribs
    attribs.each { |k, v| instance_variable_set("@#{k}", v) }

    @subsets ||= []

    # if all subsets are no_data, the whole collection is no_data!
    @no_data = subsets.empty? || subsets.all?(&:no_data?)
  end

  def no_data?
    @no_data
  end

  # does as it says
  def remove_null_subset_if_empty!
    null_subset = subsets.detect { |s| s.disagg_value.nil? }
    subsets.delete(null_subset) if null_subset.try(:no_data?)
  end

  # merges this collection with the given one. combines subsets with the same disagg_value
  def merge(other)
    ours_by_disagg_value = subsets.index_by(&:disagg_value)
    other.subsets.each do |theirs|
      # if we already have a subset with this disagg_value, just append the summaries
      if ours = ours_by_disagg_value[theirs.disagg_value]
        ours.append_summaries(theirs.summaries)
      # else add the subset to ours
      else
        @subsets << theirs
        ours_by_disagg_value[theirs.disagg_value] = theirs
      end

      # keep the no_data flag updated
      @no_data = false unless theirs.no_data?
    end
  end
end
