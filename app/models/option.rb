# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: options
#
#  id                :uuid             not null, primary key
#  canonical_name    :string(255)      not null
#  latitude          :decimal(8, 6)
#  longitude         :decimal(9, 6)
#  name_translations :jsonb            not null
#  value             :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  mission_id        :uuid
#
# Indexes
#
#  index_options_on_canonical_name     (canonical_name)
#  index_options_on_mission_id         (mission_id)
#  index_options_on_name_translations  (name_translations) USING gin
#
# Foreign Keys
#
#  options_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

# A single selectable option in an OptionSet for a select question.
# Option should be one-to-one with OptionNode (rather vestigial, and eventually being deprecated).
#
# See also the documentation at docs/architecture.md.
class Option < ApplicationRecord
  include Replication::Replicable
  include Translatable
  include MissionBased

  MAX_NAME_LENGTH = 255
  LAT_LNG_REGEXP = /^(-?\d+(\.\d+)?)\s*[,;:\s]\s*(-?\d+(\.\d+)?)/.freeze

  has_many :option_nodes, -> { order(:rank) }, inverse_of: :option, dependent: :destroy, autosave: true
  has_many :option_sets, through: :option_nodes

  before_validation :normalize
  after_destroy :invalidate_cache
  after_save :invalidate_cache

  scope :with_questions_and_forms,
    -> { includes(option_sets: [:questionings, {questions: {questionings: :form}}]) }
  scope :by_canonical_name, ->(name) { where("LOWER(canonical_name) = ?", name.downcase) }

  translates :name

  validate :check_invalid_coordinates_flag
  with_options if: :coordinates? do
    validates :latitude, numericality: {greater_than_or_equal_to: -90, less_than_or_equal_to: 90}
    validates :longitude, numericality: {greater_than_or_equal_to: -180, less_than_or_equal_to: 180}
  end

  # We re-use options on replicate if they have the same canonical_name as the option being imported.
  # Options are not standardizable so we don't track the original_id (that would be overkill).
  replicable reuse_if_match: :canonical_name

  def published?
    option_sets.any?(&:published?)
  end

  def questions
    option_sets.map(&:questions).flatten.uniq
  end

  def coordinates?
    latitude.present? || longitude.present?
  end

  # returns all forms on which this option appears
  def forms
    option_sets.map { |os| os.questionings.map(&:form) }.flatten.uniq
  end

  # Returns an Option in the given mission that has same canonical name as this Option.
  # Returns nil if not found.
  def similar_for_mission(other_mission)
    self.class.find_by(canonical_name: canonical_name, mission_id: other_mission&.id)
  end

  def coordinates
    "#{latitude}, #{longitude}" if coordinates?
  end

  def coordinates=(value)
    @_invalid_coordinates_flag = false

    if value.blank?
      self.latitude = nil
      self.longitude = nil
    elsif (match = value.match(LAT_LNG_REGEXP))
      self.latitude = match[1].to_d.truncate(6)
      self.longitude = match[3].to_d.truncate(6)
    else
      @_invalid_coordinates_flag = true
    end
  end

  private

  def normalize
    return unless value.is_a?(String)
    value.strip!
    self.value = numeric?(value) ? value.to_i : nil
  end

  def numeric?(str)
    Float(str)
    true
  rescue ArgumentError
    false
  end

  # invalidate the mission option cache after save, destroy
  def invalidate_cache
    Rails.cache.delete("mission_options/#{mission_id}")
  end

  def check_invalid_coordinates_flag
    errors.add(:coordinates, :invalid_coordinates) if @_invalid_coordinates_flag
  end
end
