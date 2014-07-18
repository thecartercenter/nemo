class OptionNode < ActiveRecord::Base
  include MissionBased

  attr_accessible :ancestry, :option_id, :option_set, :option_set_id, :rank, :option, :option_attribs, :children_attribs

  belongs_to :option_set
  belongs_to :option, :autosave => true
  has_ancestry

  before_validation :copy_mission_to_option
  after_save :update_children

  attr_accessor :children_attribs
  attr_reader :option_attribs

  # Copy the mission ID from the option set.
  def option_set=(set)
    association(:option_set).writer(set)
    self.mission = set.mission
  end

  def option_attribs=(attribs)
    attribs.symbolize_keys!
    if attribs[:id]
      self.option = Option.find(attribs[:id])
      option.assign_attributes(attribs)
    else
      build_option(attribs)
    end
  end

  private

    # Special method for creating/updating a tree of nodes via the children_attribs hash
    def update_children
      reload # Ancestry doesn't seem to work properly without this.
      copy_mission_to_children_attribs # Need this or we get a validation error.

      (children_attribs || []).each_with_index do |c, i|
        children.create!(c.merge(option_set: option_set, rank: i + 1))
      end
    end

    def copy_mission_to_option
      option.mission = mission if option && option.mission.nil?
      return true
    end

    def copy_mission_to_children_attribs
      (children_attribs || []).each do |c|
        c[:option_attributes][:mission_id] = mission.id if c[:option_attributes]
        c['option_attributes'][:mission_id] = mission.id if c['option_attributes']
      end
    end
end
