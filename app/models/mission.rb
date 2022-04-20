# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: missions
#
#  id           :uuid             not null, primary key
#  compact_name :string(255)      not null
#  locked       :boolean          default(FALSE), not null
#  name         :string(255)      not null
#  shortcode    :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_missions_on_compact_name  (compact_name) UNIQUE
#  index_missions_on_shortcode     (shortcode) UNIQUE
#
# rubocop:enable Layout/LineLength

class Mission < ApplicationRecord
  CODE_CHARS = ("a".."z").to_a + ("0".."9").to_a
  CODE_LENGTH = 2

  has_many :responses, inverse_of: :mission
  has_many :response_nodes, inverse_of: :mission
  has_many :forms, inverse_of: :mission
  has_many :report_reports, class_name: "Report::Report", inverse_of: :mission
  has_many :broadcasts, inverse_of: :mission
  has_many :assignments, inverse_of: :mission
  has_many :users, through: :assignments
  has_many :user_groups, inverse_of: :mission, dependent: :destroy
  has_many :user_group_assignments, through: :user_groups
  has_many :questions, inverse_of: :mission
  has_many :qing_groups, inverse_of: :mission
  has_many :form_items, inverse_of: :mission
  has_many :conditions, inverse_of: :mission
  has_many :operations, inverse_of: :mission, dependent: :destroy
  has_many :options, inverse_of: :mission, dependent: :destroy
  has_many :option_sets, inverse_of: :mission, dependent: :destroy
  has_many :option_nodes, inverse_of: :mission, dependent: :destroy
  has_one :setting, inverse_of: :mission, dependent: :destroy
  has_many :skip_rules, inverse_of: :mission, dependent: :destroy
  has_many :constraints, inverse_of: :mission, dependent: :destroy

  before_validation :create_compact_name
  before_create :ensure_setting
  before_create :generate_shortcode

  validates :name, presence: true
  validates :name, format: {with: /\A[a-z][a-z0-9 ]*\z/i, message: :let_num_spc_only},
                   length: {minimum: 3, maximum: 32}, if: proc { |m| m.name.present? }
  validate :compact_name_unique

  scope :sorted_by_name, -> { order(Arel.sql("LOWER(name)")) }
  scope :sorted_recent_first, -> { order(created_at: :desc) }

  clone_options follow: %i[setting]

  delegate :override_code, :default_locale, to: :setting

  # Raises ActiveRecord::RecordNotFound if not found.
  def self.with_compact_name(name)
    where(compact_name: name).first || (raise ActiveRecord::RecordNotFound, "Mission not found")
  end

  # checks to make sure there are no associated objects.
  def check_associations
    to_check = %i[assignments responses forms report_reports questions broadcasts]
    to_check.each { |a| raise DeletionError, :cant_delete_if_assoc unless send(a).empty? }
  end

  # DEPRECATED: This should go away and be replaced with use of destroy and a background job.
  # No need to maintain all this extra logic. Mission delete happens rarely and can be slow.
  def destroy
    transaction do
      # The order of deletion is also important to avoid foreign key constraints
      [Setting, Report::Report].each { |r| r.mission_pre_delete(self) }
      ResponseDestroyer.new(scope: Response.where(mission: self)).destroy!
      relationships_to_delete = [Condition, FormItem, Question, OptionSet, Option,
                                 Form, Broadcast, Assignment, Sms::Message, UserGroup, Operation]
      relationships_to_delete.each { |r| r.mission_pre_delete(self) }
      reload
      check_associations
      delete
    end
  end

  def generate_shortcode
    loop do
      self.shortcode = CODE_LENGTH.times.map { CODE_CHARS.sample }.join
      break unless Mission.exists?(shortcode: shortcode)
    end
  end

  # returns a string representation used for debugging
  def to_s
    "#{id}(#{compact_name})"
  end

  private

  def create_compact_name
    self.compact_name = name.delete(" ").downcase
    true
  end

  def compact_name_unique
    if name.present? && matching = (self.class.where(compact_name: compact_name).to_a - [self]).first
      errors.add(:name, :not_unique, existing: matching.name)
    end
  end

  # creates an accompanying settings object composed of defaults, unless one exists
  def ensure_setting
    self.setting ||= Setting.build_default(mission: self)
  end
end
