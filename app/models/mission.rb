class Mission < ApplicationRecord
  acts_as_paranoid

  CODE_CHARS = ("a".."z").to_a + ("0".."9").to_a
  CODE_LENGTH = 2

  has_many(:responses, inverse_of: :mission)
  has_many(:forms, inverse_of: :mission)
  has_many(:report_reports, class_name: "Report::Report", inverse_of: :mission)
  has_many(:broadcasts, inverse_of: :mission)
  has_many(:assignments, inverse_of: :mission)
  has_many(:users, through: :assignments)
  has_many(:user_groups, inverse_of: :mission, dependent: :destroy)
  has_many(:user_group_assignments, through: :user_groups)
  has_many(:questions, inverse_of: :mission)
  has_many(:qing_groups, inverse_of: :mission)
  has_many(:form_items, inverse_of: :mission)
  has_many(:conditions, inverse_of: :mission)
  has_many(:options, inverse_of: :mission, dependent: :destroy)
  has_many(:option_sets, inverse_of: :mission, dependent: :destroy)
  has_many(:option_nodes, inverse_of: :mission, dependent: :destroy)
  has_many(:taggings, inverse_of: :mission, dependent: :destroy)
  has_one(:setting, inverse_of: :mission, dependent: :destroy)

  before_validation(:create_compact_name)
  before_create(:ensure_setting)
  before_create(:generate_shortcode)

  validates(:name, presence: true)
  validates(:name, format: { with: /\A[a-z][a-z0-9 ]*\z/i, message: :let_num_spc_only },
                   length: { minimum: 3, maximum: 32 },
                   if: Proc.new { |m| !m.name.blank? })
  validate(:compact_name_unique)

  scope(:sorted_by_name, -> { order("name") })
  scope(:sorted_recent_first, -> { order("missions.created_at DESC") })
  scope(:for_user, ->(u) { where("missions.id IN
    (SELECT mission_id FROM assignments WHERE deleted_at IS NULL AND user_id = ?)", u.id) })

  delegate(:override_code, :allow_unauthenticated_submissions?, :default_locale, to: :setting)

  # Raises ActiveRecord::RecordNotFound if not found.
  def self.with_compact_name(name)
    where(compact_name: name).first || (raise ActiveRecord::RecordNotFound.new("Mission not found"))
  end

  # checks to make sure there are no associated objects.
  def check_associations
    to_check = [:assignments, :responses, :forms, :report_reports, :questions, :broadcasts]
    to_check.each { |a| raise DeletionError.new(:cant_delete_if_assoc) unless self.send(a).empty? }
  end

  # remove this mission and other related records from the Database
  # * this method is designed for speed.
  def destroy
    ApplicationRecord.transaction do
      begin
        # Remove MissionBased Classes
        # note that we don't need to remove OptionNodes directly since OptionSet takes care of that
        # the order of deletion is also important to avoid foreign key constraints
        relationships_to_delete = [Setting, Report::Report, Condition, FormItem,
                                   Question, OptionSet, Option, Response,
                                   Form, Broadcast, Assignment, Sms::Message, UserGroup]
        relationships_to_delete.each { |r| r.mission_pre_delete(self) }

        reload
        check_associations
        delete
      rescue Exception => e
        Rails.logger.error "We had to rescue from the delete for mission: #{self.id}-#{self.name}. #{e}"
        raise e
      end
    end
  end

  def generate_shortcode
    begin
      self.shortcode = CODE_LENGTH.times.map { CODE_CHARS.sample }.join
    end while Mission.exists?(shortcode: self.shortcode)
  end

  # returns a string representation used for debugging
  def to_s
    "#{id}(#{compact_name})"
  end

  private

  def create_compact_name
    self.compact_name = name.gsub(" ", "").downcase
    true
  end

  def compact_name_unique
    if !name.blank? && matching = (self.class.where(compact_name: compact_name).to_a - [self]).first
      errors.add(:name, :not_unique, existing: matching.name)
    end
  end

  # creates an accompanying settings object composed of defaults, unless one exists
  def ensure_setting
    self.setting ||= Setting.build_default(self)
  end
end
