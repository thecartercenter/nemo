module Standardizable
  extend ActiveSupport::Concern

  included do
    # create a flag to use with the callback below
    attr_accessor :saving_in_replication

    # create self-associations in both directions for is-copy-of relationship
    belongs_to(:standard, :class_name => name, :inverse_of => :copies)
    has_many(:copies, :class_name => name, :foreign_key => 'standard_id', :inverse_of => :standard)

    # create hooks to replicate changes to copies
    after_save(:replicate_changes_to_copies)
  end

  # get copy in the given mission, if it exists (there can only be one)
  def copy_for_mission(mission)
    respond_to?(:mission) ? copies.for_mission(mission).first : nil
  end

  private
    def replicate_changes_to_copies
      puts "doing standardizable callback"
      if saving_in_replication
        saving_in_replication = false
        puts "cancelled"
      else
        puts "calling replicate"
        # if we just run replicate for each copy's mission, all changes will be propagated
        copies.each{|c| replicate(c.mission)}
      end
    end
end