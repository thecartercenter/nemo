module OptioningParentable
  extend ActiveSupport::Concern

  # checks if any options have been added since last save
  def options_added?
    is_a?(Optioning) && new_record? || optionings.any?(&:options_added?)
  end

  # checks if any of the options in this set have changed position (rank or parent) since last save
  # trivially true if this is a new object
  def positions_changed?
    # first check self (unless self is an OptionSet), then check children if necessary
    is_a?(Optioning) && signature_changed? || optionings.any?(&:positions_changed?)
  end

  protected
    # makes sure, recursively, that the options in the set have sequential ranks starting at 1.
    def ensure_children_ranks
      optionings.ensure_contiguous_ranks
      optionings.each{|c| c.ensure_children_ranks}
    end
end