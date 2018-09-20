# frozen_string_literal: true

# A single selectable option in an OptionSet for a select question.
class Option < ApplicationRecord
  include Replication::Replicable
  include Translatable
  include FormVersionable
  include MissionBased

  MAX_NAME_LENGTH = 255
  LAT_LNG_REGEXP = /^(-?\d+(\.\d+)?)\s*[,;:\s]\s*(-?\d+(\.\d+)?)/

  acts_as_paranoid

  has_many :option_nodes, -> { order(:rank) }, inverse_of: :option, dependent: :destroy, autosave: true
  has_many :option_sets, through: :option_nodes
  has_many :answers, inverse_of: :option, dependent: :restrict_with_exception
  has_many :choices, inverse_of: :option, dependent: :restrict_with_exception

  before_validation :normalize
  after_save :invalidate_cache
  after_save :touch_answers_choices
  after_destroy :invalidate_cache

  scope :with_questions_and_forms,
    -> { includes(option_sets: [:questionings, questions: {questionings: :form}]) }
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

  def has_answers?
    !answers.empty?
  end

  def has_choices?
    !choices.empty?
  end

  def coordinates?
    latitude.present? || longitude.present?
  end

  # returns all forms on which this option appears
  def forms
    option_sets.map { |os| os.questionings.map(&:form) }.flatten.uniq
  end

  # returns whether this option is in use -- is referenced in any answers/choices AND/OR is published
  def in_use?
    published? || has_answers? || has_choices?
  end

  # gets the names of all option sets in which this option appears
  def set_names
    option_sets.map(&:name).join(", ")
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

  def as_json(options = {})
    if options[:for_option_set_form]
      super(only: %i[id latitude longitude name_translations value],
            methods: %i[name set_names in_use?])
    else
      super(options)
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

  # Touch these objects so the search index is updated.
  def touch_answers_choices
    answers.each(&:touch)
    choices.each(&:touch)
  end

  def check_invalid_coordinates_flag
    errors.add(:coordinates, :invalid_coordinates) if @_invalid_coordinates_flag
  end
end
