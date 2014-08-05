class Answer < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  belongs_to(:questioning, :inverse_of => :answers)
  belongs_to(:option, :inverse_of => :answers)
  belongs_to(:response, :inverse_of => :answers, :touch => true)
  has_many(:choices, :dependent => :destroy, :inverse_of => :answer)

  before_validation(:clean_locations)
  before_save(:round_ints)
  before_save(:blanks_to_nulls)

  validates(:value, :numericality => true, :if => ->(a){ a.should_validate?(:numericality) })

  # in these custom validations, we add errors to the base, but we don't use full sentences (e.g. we use 'is required')
  # since this class really just represents one value
  validate(:min_max, :if => ->(a){ a.should_validate?(:min_max) })
  validate(:required, :if => ->(a){ a.should_validate?(:required) })

  delegate :question, :qtype, :rank, :required?, :hidden?, :option_set, :options, :condition, :to => :questioning
  delegate :name, :hint, :to => :question, :prefix => true

  scope :public_access, includes(:questioning => :question).
                        where("questions.access_level = 'inherit'")

  # creates a new answer from a string from odk
  def self.new_from_str(params)
    str = params.delete(:str)
    ans = new(params)

    # if there was no answer to this question (in the case of a out of sync form) just leave it blank
    return ans if str.nil?

    # set the attributes based on the question type
    if ans.qtype.name == "select_one"
      ans.option_id = str.to_i
    elsif ans.qtype.name == "select_multiple"
      str.split(" ").each{|oid| ans.choices.build(:option_id => oid.to_i)}
    elsif ans.qtype.temporal?
      # parse the string into a time
      val = Time.zone.parse(str)

      # convert the parsed time to the appropriate database format unless question is timezone sensitive
      val = val.to_s(:"db_#{ans.qtype.name}") unless ans.qtype.has_timezone?

      # assign the value
      ans.send("#{ans.qtype.name}_value=", val)
    else
      ans.value = str
    end
    ans
  end

  # gets all location answers for the given mission
  # returns only the response ID and the answer value
  def self.location_answers_for_mission(mission, user = nil)
    user_clause = user ? "AND r.user_id = #{user.id}" : ''
    find_by_sql([
      "SELECT r.id AS r_id, a.value AS loc
      FROM answers a
        INNER JOIN responses r ON a.response_id = r.id
        INNER JOIN questionings qing ON a.questioning_id = qing.id
        INNER JOIN questions q ON qing.question_id = q.id
      WHERE q.qtype_name = 'location' AND a.value IS NOT NULL AND r.mission_id = ? #{user_clause}",
      mission.id
    ])
  end

  # Tests if there exists at least one answer referencing the Option with the given ID.
  def self.any_for_option?(option_id)
    connection.execute("SELECT COUNT(*) FROM answers a LEFT OUTER JOIN choices c ON c.answer_id = a.id
      WHERE a.option_id = '#{option_id}' OR c.option_id = '#{option_id}'").to_a[0][0] > 0
  end

  def choice_for(option)
    choice_hash[option]
  end

  def choice_hash(options = {})
    if !@choice_hash || options[:rebuild]
      @choice_hash = {}; choices.each{|c| @choice_hash[c.option] = c}
    end
    @choice_hash
  end

  def all_choices
    # for each option, if we have a matching choice, return it and set it's fake bit to true
    # otherwise create one and set its fake bit to false
    options.collect do |o|
      if c = choice_for(o)
        c.checked = true
      else
        c = choices.new(:option => o, :checked => false)
      end
      c
    end
  end

  def all_choices=(params)
    # create a bunch of temp objects, discarding any unchecked choices
    submitted = params.values.collect{|p| p[:checked] == '1' ? Choice.new(p) : nil}.compact

    # copy new choices into old objects, creating or deleting if necessary
    choices.compare_by_element(submitted, Proc.new{|c| c.option_id}) do |orig, subd|
      # if both exist, do nothing
      # if submitted is nil, destroy the original
      if subd.nil?
        choices.delete(orig)
      # if original is nil, add the new one to this response's array
      elsif orig.nil?
        choices << subd
      end
    end
  end

  # if this answer is for a location question and the value is not blank, returns a two element array representing the
  # lat long. else returns nil
  def location
    if questioning.question.qtype_name == 'location' && !value.blank?
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
    when 'select_one' then option.try(:name)
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

  # checks if answer must be non-empty to be valid
  def required_and_relevant?
    required? && !hidden? && relevant? && qtype.name != "select_multiple"
  end

  # check various fields for blankness
  def empty?
    value.blank? && time_value.blank? && date_value.blank? && datetime_value.blank? && option_id.nil?
  end

  # checks if answer is required and relevant but also empty
  def required_but_empty?
    required_and_relevant? && empty?
  end

  private

    def should_validate?(field)
      # don't validate if response says no
      return false if response && !response.validate_answers?

      case field
      when :numericality
        qtype.numeric? && value.present?
      when :required
        # don't validate requiredness if response says no
        !(response && response.incomplete?)
      else
        true
      end
    end

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
      if qtype.name == "location" && !value.blank?
        if value.match(configatron.lat_lng_regexp)
          lat = number_with_precision($1.to_f, :precision => 6)
          lng = number_with_precision($3.to_f, :precision => 6)
          self.value = "#{lat} #{lng}"
        else
          self.value = ""
        end
      end
    end
end
