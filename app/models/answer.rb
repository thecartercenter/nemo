# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: answers
#
#  id                :uuid             not null, primary key
#  accuracy          :decimal(9, 3)
#  altitude          :decimal(9, 3)
#  date_value        :date
#  datetime_value    :datetime
#  latitude          :decimal(8, 6)
#  longitude         :decimal(9, 6)
#  new_rank          :integer          default(0), not null
#  old_inst_num      :integer          default(1), not null
#  old_rank          :integer          default(1), not null
#  pending_file_name :string
#  time_value        :time
#  tsv               :tsvector
#  type              :string           default("Answer"), not null
#  value             :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  mission_id        :uuid             not null
#  option_node_id    :uuid
#  parent_id         :uuid
#  questioning_id    :uuid             not null
#  response_id       :uuid             not null
#
# Indexes
#
#  index_answers_on_mission_id      (mission_id)
#  index_answers_on_new_rank        (new_rank)
#  index_answers_on_option_node_id  (option_node_id)
#  index_answers_on_parent_id       (parent_id)
#  index_answers_on_questioning_id  (questioning_id)
#  index_answers_on_response_id     (response_id)
#  index_answers_on_type            (type)
#
# Foreign Keys
#
#  answers_questioning_id_fkey  (questioning_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#  answers_response_id_fkey     (response_id => responses.id) ON DELETE => restrict ON UPDATE => restrict
#  fk_rails_...                 (mission_id => missions.id)
#  fk_rails_...                 (option_node_id => option_nodes.id)
#
# rubocop:enable Layout/LineLength

# An Answer is a single piece of data in response to a single question or sub-question.
# It is always a leaf in a response tree.
class Answer < ResponseNode
  include ActionView::Helpers::NumberHelper
  include PgSearch::Model
  include Wisper.model

  LOCATION_ATTRIBS = %i[latitude longitude altitude accuracy].freeze
  LOCATION_COLS = LOCATION_ATTRIBS.map(&:to_s).freeze

  # Convert value to tsvector for use in full text search.
  trigger.before(:insert, :update) do
    "new.tsv := #{Results::AnswerSearchVectorUpdater.instance.trigger_expression};"
  end

  attr_accessor :location_values_replicated

  alias questioning form_item

  belongs_to :response, inverse_of: :answers, touch: true
  has_one :media_object, dependent: :destroy, inverse_of: :answer, autosave: true, class_name: "Media::Object"

  before_validation :replicate_location_values
  before_save :replicate_location_values # Doing this twice on purpose, see below.
  before_save :chop_decimals
  before_save :format_location_value
  before_save :round_ints
  before_save :blanks_to_nulls
  before_save :remove_unchecked_choices
  after_save :reset_location_flag

  validates :value, numericality: true, if: -> { should_validate?(:numericality) }
  validate :validate_min_max, if: -> { should_validate?(:min_max) }
  validate :validate_required, if: -> { should_validate?(:required) }
  validate :validate_location, if: -> { should_validate?(:location) }
  validate :validate_date, :validate_datetime

  accepts_nested_attributes_for(:choices)

  delegate :question, :qtype, :qtype_name, :required?, :visible?, :enabled?, :multimedia?,
    :option_set, :option_set_id, :options, :first_level_option_nodes, :condition,
    :parent_group_name, to: :questioning
  delegate :name, :code, to: :question, prefix: true
  delegate :name, to: :level, prefix: true, allow_nil: true
  delegate :name, to: :option_node, prefix: true, allow_nil: true
  delegate :mission, to: :response

  scope :public_access, lambda {
    joins(form_item: :question)
      .where("questions.access_level = 'inherit'").order("form_items.rank")
  }
  scope :created_after, ->(date) { includes(:response).where("responses.created_at >= ?", date) }
  scope :created_before, ->(date) { includes(:response).where("responses.created_at <= ?", date) }
  scope :first_level_only, lambda { # exclude answers from answer sets that are not first level
    joins("INNER JOIN answers parents ON answers.parent_id = parents.id")
      .where("parents.type != 'AnswerSet' OR answers.new_rank = 0")
  }

  # Allow searching for various kinds of answer values (such as option ID, date, etc.)
  # See answer_search_vector_updater.rb for details.
  pg_search_scope :search_by_value,
    against: :value,
    using: {
      tsearch: {
        tsvector_column: "tsv",
        prefix: true,
        negation: true
      }
    }

  def option_name
    option_node&.name
  end

  # If this is an answer to a multilevel select_one question, returns the OptionLevel, else returns nil.
  def level
    option_set.try(:multilevel?) ? option_set.levels[(rank || 1) - 1] : nil
  end

  # if this answer is for a location question and the value is not blank,
  # returns a two element array representing the lat long. else returns nil
  def location
    value.split(" ") if location_type_with_value?
  end

  # returns the value for this answer casted to the appropriate data type
  def casted_value
    case qtype.name
    when "date" then date_value
    when "time" then time_value
    when "datetime" then datetime_value
    when "integer", "counter" then value.try(:to_i)
    when "decimal" then value.try(:to_f)
    when "select_one" then option_name
    when "select_multiple" then choices.empty? ? nil : choices.map(&:option_name).sort.join(";")
    else value.presence
    end
  end

  def lengthy?
    value.present? && value.size >= 1000
  end

  # Whether this Answer is the first in its set (i.e. rank is nil or 1)
  def first_rank?
    new_rank.nil? || new_rank.zero?
  end

  # check various fields for blankness
  def empty?
    value.blank? && time_value.blank? && date_value.blank? &&
      datetime_value.blank? && option_node_id.nil? && media_object.nil?
  end
  alias blank? empty?

  def location_type_with_value?
    qtype.name == "location" && value.present?
  end

  def coordinates?
    latitude.present? && longitude.present?
  end

  def from_group?
    questioning&.parent && questioning.parent.type == "QingGroup"
  end

  def media_object_id
    media_object&.id
  end

  # Attempts to find unassociated media object with given ID and assoicate with this answer.
  # Fails silently if not found.
  def media_object_id=(id)
    if id.nil?
      self.media_object = nil
    elsif media_object_id != id
      self.media_object = Media::Object.find_by(id: id, answer_id: nil)
    end

    # Manually mark as dirty since the creation of media objects
    # is difficult to listen for otherwise.
    Rails.logger.debug("OData dirty_json cause: media_object_id=#{id}")
    response&.update!(dirty_json: true)
  end

  def media_object?
    !media_object.nil?
  end

  def group_level
    questioning.ancestry_depth - 1
  end

  private

  def should_validate?(field)
    # TODO: This line seems to trigger an unnecessary query if response is assigned before it is saved.
    # That is the current theory anyway. A workaround might be to have an ephemeral skip_validation flag
    # when building the object, and call that from the decoder and ODK parser.
    # As it is, the query should be cached, so performance hit shouldn't be too bad.
    return false if response && !response.validate_answers?
    return false if marked_for_destruction?

    case field
    when :numericality
      qtype.numeric? && value.present?
    when :required
      # don't validate requiredness if response says no
      !(response && response.incomplete?)
    when :min_max
      value.present?
    when :location
      qtype.name == "location"
    else
      true
    end
  end

  def parse_token(token)
    BigDecimal(token)
  rescue ArgumentError
    # token was not parsable
    nil
  rescue TypeError
    # token was not a parsable type
    nil
  end

  def replicate_location_values
    # This method is run before_validation and before_save in case validations are skipped.
    # We use this flag to not duplicate effort.
    return if location_values_replicated
    self.location_values_replicated = true

    choices.each(&:replicate_location_values)

    if location_type_with_value?
      tokens = value.split(" ")
      LOCATION_ATTRIBS.each_with_index do |a, i|
        self[a] = parse_token(tokens[i])
      end
    elsif option_node&.coordinates?
      self.latitude = option_node.latitude
      self.longitude = option_node.longitude
    end
    true
  end

  # We sometimes save decimals without validating, so we need to be careful
  # not to overflow the DB.
  def chop_decimals
    LOCATION_ATTRIBS.each do |a|
      next if self[a].nil?
      column = self.class.column_for_attribute(a)
      self[a] = 0 if self[a].abs > 10**(column.precision - column.scale)
    end
    self.accuracy = 0 if accuracy.present? && accuracy.negative?
    true
  end

  def format_location_value
    if coordinates?
      self.value = format("%.6f %.6f", latitude, longitude)
      if altitude.present?
        value << format(" %.3f", altitude)
        value << format(" %.3f", accuracy) if accuracy.present?
      end
    end
    true
  end

  def round_ints
    self.value = value.to_i if %w[integer counter].include?(qtype.name) && value.present?
    true
  end

  def blanks_to_nulls
    self.value = nil if value.blank?
    true
  end

  def remove_unchecked_choices
    choices.destroy(*choices.reject(&:checked?))
    true
  end

  def validate_required
    return unless empty? && required? && visible? && relevant? && !qtype.select_multiple? &&
      (first_rank? || questioning.all_levels_required?)
    errors.add(:value, :required)
  end

  def validate_min_max
    val_f = value.to_f
    if question.maximum && (val_f > question.maximum || question.maxstrictly && val_f == question.maximum) ||
        question.minimum && (val_f < question.minimum || question.minstrictly && val_f == question.minimum)
      errors.add(:value, question.min_max_error_msg)
    end
  end

  def validate_location
    # Doesn't make sense to validate lat/lng if copied from options because the user
    # can't do anything about that.
    if location_type_with_value?
      errors.add(:value, :invalid_latitude) if latitude.nil? || latitude < -90 || latitude > 90
      errors.add(:value, :invalid_longitude) if longitude.nil? || longitude < -180 || longitude > 180
      errors.add(:value, :invalid_altitude) if altitude.present? && (altitude >= 1e6 || altitude <= -1e6)
      if accuracy.present?
        if accuracy.negative?
          errors.add(:value, :accuracy_negative)
        elsif accuracy >= 1e6
          errors.add(:value, :invalid_accuracy)
        end
      end
    end
  end

  def reset_location_flag
    self.location_values_replicated = false
    true
  end

  def validate_date
    # The date_value before typecast may be a string or a hash (in the case of a multiparam attrib
    # submission like date_value(1i), date_value(2i), etc.) If it is an invalid string, Rails silently
    # coerces it to nil without setting a validation error or raises an error. We want to show a validation
    # error instead.
    return if raw_date_value_ok?("date_value")
    errors.add(:date_value, :invalid_date)
  end

  def validate_datetime
    # See comment for the validate_date method above. The same applies here.
    return if raw_date_value_ok?("datetime_value")
    errors.add(:datetime_value, :invalid_datetime)
  end

  def raw_date_value_ok?(attrib_name)
    raw = read_attribute_before_type_cast(attrib_name)
    return true if raw.blank? || raw.is_a?(Hash)
    begin
      Time.zone.parse(raw.to_s) && true
    rescue ArgumentError
      false
    end
  end
end
