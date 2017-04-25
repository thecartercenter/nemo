# An Answer is a single piece of data in response to a single question or sub-question.
#
# A note about rank/inst_num attributes
#
# rank:
# - The rank of the answer within a given set of answers for a multilevel select question.
# - Starts at 1 (top level) and increases
# - Should be 1 for non-multilevel questions
#
# inst_num:
# - The number of the set of answers in which this answer belongs
# - Starts at 1 (first instance) and increases
# - e.g. if a response has three instances of a given group, values will be 1, 2, 3, and
#   there will be N answers in instance 1, N in instance 2, etc., where N is the number of Q's in the group
# - Should be 1 for answers to top level questions and questions in non-repeating groups
# - Questions with answers with inst_nums higher than 1 shouldn't be allowed to be moved.
#
class Answer < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  belongs_to(:questioning, inverse_of: :answers)
  belongs_to(:option, inverse_of: :answers)
  belongs_to(:response, inverse_of: :answers, touch: true)
  has_many(:choices, dependent: :destroy, inverse_of: :answer, autosave: true)
  has_one(:media_object, dependent: :destroy, autosave: true, class_name: 'Media::Object')

  before_validation(:clean_locations)
  before_save(:replicate_location_values)
  before_save(:round_ints)
  before_save(:blanks_to_nulls)

  # Remove unchecked choices before saving.
  before_save do
    choices.destroy(*choices.reject(&:checked?))
  end

  validates(:value, numericality: true, if: ->(a){ a.should_validate?(:numericality) })

  # in these custom validations, we add errors to the base, but we don't use full sentences (e.g. we use 'is required')
  # since this class really just represents one value
  validate(:min_max, if: ->(a){ a.should_validate?(:min_max) })
  validate(:required, if: ->(a){ a.should_validate?(:required) })

  accepts_nested_attributes_for(:choices)

  delegate :question, :qtype, :required?, :hidden?, :multimedia?,
    :option_set, :options, :first_level_option_nodes, :condition, to: :questioning
  delegate :name, :hint, to: :question, prefix: true
  delegate :name, to: :level, prefix: true, allow_nil: true
  delegate :mission, to: :response

  scope :public_access, -> { joins(questioning: :question).
    where("questions.access_level = 'inherit'") }
  scope :created_after, ->(date) { includes(:response).where("responses.created_at >= ?", date) }
  scope :created_before, ->(date) { includes(:response).where("responses.created_at <= ?", date) }
  scope :newest_first, -> { includes(:response).order("responses.created_at DESC") }

  # gets all location answers for the given mission
  # returns only the response ID and the answer value
  def self.location_answers_for_mission(mission, user = nil, options = {})
    response_conditions = { mission_id: mission.try(:id) }

    # if the user is not a staffer or higher privilege, only show their own responses
    if user.present? && !user.role?(:staffer, mission)
      response_conditions[:user_id] = user.id
    end

    # return an AR relation
    joins(:response)
      .joins(%{LEFT JOIN `choices` ON `choices`.`answer_id` = `answers`.`id`})
      .where(responses: response_conditions)
      .where(%{
        (`answers`.`latitude` IS NOT NULL AND `answers`.`longitude` IS NOT NULL)
        OR (`choices`.`latitude` IS NOT NULL AND `choices`.`longitude` IS NOT NULL)
      })
      .select(:response_id,
        %{COALESCE(`answers`.`latitude`, `choices`.`latitude`) AS `latitude`,
          COALESCE(`answers`.`longitude`, `choices`.`longitude`) AS `longitude`})
      .order('`answers`.`response_id` DESC')
      .paginate(page: 1, per_page: 1000)
  end

  # Tests if there exists at least one answer referencing the option and questionings with the given IDs.
  def self.any_for_option_and_questionings?(option_id, questioning_ids)
    find_by_sql(["SELECT COUNT(*) AS count FROM answers a LEFT OUTER JOIN choices c ON c.answer_id = a.id
      WHERE (a.option_id = ? OR c.option_id = ?) AND a.questioning_id IN (?)", option_id, option_id, questioning_ids]).first.count > 0
  end

  # This is a temporary method for fetching option_node based on the related OptionSet and Option.
  # Eventually Options will be removed and OptionNodes will be stored on Answers directly.
  def option_node
    OptionNode.where(option_id: option_id, option_set_id: option_set.id).first
  end

  def option_node_id
    option_node.try(:id)
  end

  # This is a temporary method for assigning option based on an OptionNode ID.
  # Eventually Options will be removed and OptionNodes will be stored on Answers directly.
  def option_node_id=(id)
    self.option_id = id.present? ? OptionNode.id_to_option_id(id) : nil
  end

  # If this is an answer to a multilevel select_one question, returns the OptionLevel, else returns nil.
  def level
    option_set.try(:multilevel?) ? option_set.levels[(rank || 1) - 1] : nil
  end

  def choices_by_option
    @choice_hash ||= choices.select(&:checked?).index_by(&:option)
  end

  def all_choices
    # for each option, if we have a matching choice, just return it (checked? defaults to true)
    # otherwise create one and set checked? to false
    options.map{ |o| choices_by_option[o] || choices.new(option: o, checked: false) }
  end

  # if this answer is for a location question and the value is not blank, returns a two element array representing the
  # lat long. else returns nil
  def location
    if simple_location_answer?
      value.split(' ')
    else
      nil
    end
  end

  # returns the value for this answer casted to the appropriate data type
  def casted_value
    case qtype.name
    when 'date' then date_value
    when 'time' then time_value
    when 'datetime' then datetime_value
    when 'integer' then value.try(:to_i)
    when 'decimal' then value.try(:to_f)
    when 'select_one' then option_name
    when 'select_multiple' then choices.empty? ? nil : choices.map(&:option_name).join(';')
    else value.blank? ? nil : value
    end
  end

  # relevant defaults to true until set otherwise
  def relevant?
    @relevant.nil? ? true : @relevant
  end
  alias_method :relevant, :relevant?

  # A flag indicating whether the answer is relevant and should thus be validated.
  # convert string 'true'/'false' to boolean
  def relevant=(r)
    @relevant = r.is_a?(String) ? r == "true" : r
  end

  # Checks if answer must be non-empty to be valid.
  # Non-first-rank answers are currently not required even if their questioning is required (i.e. partial answers allowed).
  def required_and_relevant?
    required? && !hidden? && relevant? && first_rank? && qtype.name != "select_multiple"
  end

  # Whether this Answer is the first in its set (i.e. rank is nil or 1)
  def first_rank?
    rank.nil? || rank == 1
  end

  # check various fields for blankness
  def empty?
    value.blank? && time_value.blank? && date_value.blank? &&
      datetime_value.blank? && option_id.nil? && media_object.nil?
  end
  alias_method :blank?, :empty?

  # checks if answer is required and relevant but also empty
  def required_but_empty?
    required_and_relevant? && empty?
  end

  def should_validate?(field)
    # don't validate if response says no
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
    else
      true
    end
  end

  def simple_location_answer?
    qtype.name == 'location' && value.present?
  end

  # check whether this answer has coordinates
  def has_coordinates?
    return false unless qtype.has_options?

    if option.present?
      # select_one
      option.has_coordinates?
    else
      # select_multiple
      choices.any?(&:has_coordinates?)
    end
  end

  def from_group?
    questioning && questioning.parent && questioning.parent.type == 'QingGroup'
  end

  def option_name
    option.canonical_name if option
  end

  def option_names
    choices.map(&:option).map(&:canonical_name).join(', ') if choices
  end

  def lat_lng
    latitude.present? && longitude.present? ? [latitude, longitude] : nil
  end

  # Used with nested attribs
  def media_object_id
    media_object.try(:id)
  end

  # Used with nested attribs
  # Attempts to find unassociated media object with given ID and assoicate with this answer.
  # Fails silently if not found.
  def media_object_id=(id)
    if id.nil?
      self.media_object = nil
    elsif media_object_id != id.to_i
      self.media_object = Media::Object.find_by(id: id, answer_id: nil)
    end
  end

  def has_media_object?
    !media_object_id.nil?
  end

  def repeat_level
    questioning.ancestry_depth - 1
  end

  private

    def required
      errors.add(:value, :required) if required_but_empty?
    end

    def round_ints
      self.value = value.to_i if qtype.name == "integer" && !value.blank?
      return true
    end

    def blanks_to_nulls
      self.value = nil if value.blank?
      return true
    end

    def min_max
      val_f = value.to_f
      if question.maximum && (val_f > question.maximum || question.maxstrictly && val_f == question.maximum) ||
         question.minimum && (val_f < question.minimum || question.minstrictly && val_f == question.minimum)
        errors.add(:value, question.min_max_error_msg)
      end
    end

    def clean_locations
      if simple_location_answer?
        if value.match(configatron.lat_lng_regexp)
          lat = number_with_precision($1.to_f, precision: 6)
          lng = number_with_precision($3.to_f, precision: 6)
          self.value = "#{lat} #{lng}"
        else
          self.value = ""
        end
      end
    end

    def replicate_location_values
      if simple_location_answer?
        lat, long = self.value.split(' ')
        self.latitude = BigDecimal.new(lat)
        self.longitude = BigDecimal.new(long)
      elsif option.present? && option.has_coordinates?
        self.latitude = option.latitude
        self.longitude = option.longitude
      end
    end
end
