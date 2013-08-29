module Standardizable
  extend ActiveSupport::Concern

  included do
    # create a flag to use with the callback below
    attr_accessor :changing_in_replication

    # create self-associations in both directions for is-copy-of relationship
    belongs_to(:standard, :class_name => name, :inverse_of => :copies)
    has_many(:copies, :class_name => name, :foreign_key => 'standard_id', :inverse_of => :standard)

    # create hooks to replicate changes to copies for key classes
    after_save(:replicate_save_to_copies)
    after_destroy(:replicate_destruction_to_copies)
  end

  # get copy in the given mission, if it exists (there can only be one)
  # (we can assume that all standardizable classes are also mission-based)
  def copy_for_mission(mission)
    copies.for_mission(mission).first
  end

  private
    def replicate_changes_to_copies(change_type)
      if changing_in_replication
        changing_in_replication = false
      else
        if change_type == :destroy
          copies.each{|c| replicate_destruction(c.mission)}
        else
          # if we just run replicate for each copy's mission, all changes will be propagated
          copies.each{|c| replicate(c.mission)} if %w(Form Question Questioning OptionSet Option).include?(self.class.name)
        end
      end
    end

    def replicate_save_to_copies
      replicate_changes_to_copies(:save)
    end
    
    def replicate_destruction_to_copies
      replicate_changes_to_copies(:destroy)
    end
end