class Mission < ActiveRecord::Base
  has_many(:responses, :inverse_of => :mission)
  has_many(:forms, :inverse_of => :mission)
  has_many(:report_reports, :class_name => "Report::Report", :inverse_of => :mission)
  has_many(:broadcasts, :inverse_of => :mission)
  has_many(:assignments, :inverse_of => :mission)
  has_many(:users, :through => :assignments)
  has_many(:questions, :inverse_of => :mission)
  has_many(:questionings, :inverse_of => :mission)
  has_many(:conditions, :inverse_of => :mission)
  has_many(:options, :inverse_of => :mission, :dependent => :destroy)
  has_many(:optionings, :inverse_of => :mission, :dependent => :destroy)
  has_many(:option_sets, :inverse_of => :mission, :dependent => :destroy)
  has_one(:setting, :inverse_of => :mission, :dependent => :destroy)

  before_validation(:create_compact_name)
  before_create(:ensure_setting)

  validates(:name, :presence => true)
  validates(:name, :format => {:with => /^[a-z][a-z0-9 ]*$/i, :message => :let_num_spc_only},
                   :length => {:minimum => 3, :maximum => 32},
                   :if => Proc.new{|m| !m.name.blank?})
  validate(:compact_name_unique)

  scope(:sorted_by_name, order("name"))
  scope(:sorted_recent_first, order("created_at DESC"))
  scope(:active_for_user, lambda{|u| where("missions.id IN (SELECT mission_id FROM assignments WHERE user_id = ? AND active = 1)", u.id)})

  # Override default destory
  def destroy
    terminate_mission
  end

  # checks to make sure there are no associated objects.
  def check_associations
    to_check = [:assignments, :responses, :forms, :report_reports, :questions, :broadcasts]
    to_check.each{|a| raise DeletionError.new(:cant_delete_if_assoc) unless self.send(a).empty?}
  end

  # Remove this mission and other related records from the Database
  # * This method is designed for speed.
  def terminate_mission
    ActiveRecord::Base.transaction do
      begin
        # Remove MissionBased Classes
        relationships_to_delete = [Setting, Report::Report, Condition, Questioning,
                                   Optioning, Option, Question, OptionSet, Response,
                                   Form, Broadcast, Assignment, Sms::Message, User]
        relationships_to_delete.each{|r| r.mission_pre_delete(self)}

        self.reload
        check_associations
        self.delete
      rescue Exception => e
        Rails.logger.error "We had to rescue from the delete for mission: #{self.id}-#{self.name}. #{e}"
        raise e
      end
    end
  end

  # returns a string representation used for debugging
  def to_s
    "#{id}(#{compact_name})"
  end


  private
    def create_compact_name
      self.compact_name = name.gsub(" ", "").downcase
      return true
    end

    def compact_name_unique
      if !name.blank? && matching = (self.class.where(:compact_name => compact_name).all - [self]).first
        errors.add(:name, :not_unique, :existing => matching.name)
      end
    end

    # creates an accompanying settings object composed of defaults, unless one exists
    def ensure_setting
      self.setting ||= Setting.build_default(self)
    end
end
