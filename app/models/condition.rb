class Condition < ActiveRecord::Base
  include MissionBased, FormVersionable, Replication::Replicable

  # question types that cannot be used in conditions
  NON_REFABLE_TYPES = %w(location)

  belongs_to(:questioning, inverse_of: :condition)
  belongs_to(:ref_qing, class_name: "Questioning", foreign_key: "ref_qing_id", inverse_of: :referring_conditions)

  before_validation(:clear_blanks)
  before_validation(:clean_times)
  before_create(:set_mission)

  validate(:all_fields_required)
  validates(:questioning, presence: true)

  delegate :has_options?, to: :ref_qing, prefix: true
  delegate :form, :form_id, to: :questioning

  serialize :option_ids, JSON

  OPERATORS = [
    {name: 'eq', types: %w(decimal integer text long_text address select_one datetime date time), code: "="},
    {name: 'lt', types: %w(decimal integer datetime date time), code: "<"},
    {name: 'gt', types: %w(decimal integer datetime date time), code: ">"},
    {name: 'leq', types: %w(decimal integer datetime date time), code: "<="},
    {name: 'geq', types: %w(decimal integer datetime date time), code: ">="},
    {name: 'neq', types: %w(decimal integer text long_text address select_one datetime date time), code: "!="},
    {name: 'inc', types: %w(select_multiple), code: "="},
    {name: 'ninc', types: %w(select_multiple), code: "!="}
  ]

  replicable backward_assocs: [:questioning, :ref_qing,
      {name: :option_ids, target_class_name: 'Option', type: :serialized, skip_obj_if_missing: true}],
    dont_copy: [:ref_qing_id, :questioning_id, :option_ids]

  def options
    # We need to sort since ar#find doesn't guarantee order
    option_ids.nil? ? nil : Option.find(option_ids).sort_by{ |o| option_ids.index(o.id) }
  end

  def option_nodes
    option_ids.nil? ? nil : OptionNode.where(option_id: option_ids, option_set_id: ref_qing.option_set).sort_by { |on| option_ids.index(on.option_id) }
  end

  def option
    options.try(:first)
  end

  # Sets the first option
  def option=(o)
    self.option_ids = o.nil? ? nil : [o.id]
  end

  # Builds an OptionPath representing the selected options.
  def option_path
    @option_path ||= OptionPath.new(option_set: ref_qing.option_set, options: options)
  end

  # Accepts a hash of the form {'0' => '1234', '1' => '1238', ...} and converts to option_ids.
  def option_path_attribs=(hash)
    self.option_ids = hash.empty? ? nil : hash.values.map{ |id| id.blank? ? nil : id.to_i }.compact
  end

  # Given a rank path,  sets option_ids by getting the option path from the referred option set.
  def set_options_by_rank_path(rank_path)
    self.option_ids = ref_qing.rank_path_to_option_path(rank_path).map(&:id)
  end

  # all questionings that can be referred to by this condition
  def refable_qings
    questioning.previous.reject{|qing| NON_REFABLE_TYPES.include?(qing.qtype_name)}
  end

  # returns names of all operators that are applicable to this condition based on its referred question
  def applicable_operator_names
    ref_qing ? OPERATORS.select{|o| o[:types].include?(ref_qing.qtype_name)}.map{|o| o[:name]} : []
  end

  # Raises a ConditionOrderingError if the questioning ranks given in the ranks hash would cause
  # this condition to refer to a question later than its main question.
  # ranks - A hash of qing IDs to ranks.
  def verify_ordering(ranks)
    if questioning_id.present? && ref_qing_id.present? && ranks[questioning_id] <= ranks[ref_qing_id]
      raise ConditionOrderingError.new
    end
  end

  # Gets the definition of self's operator (self.op).
  def operator
    @operator ||= OPERATORS.detect{|o| o[:name] == op}
  end

  def to_odk
    lhs = "/data/#{ref_subquestion.odk_code}"

    if ref_qing.has_options?

      selected = "selected(#{lhs}, '#{option_nodes.last.odk_code}')"

      # Apply negation if appropriate.
      %w(neq ninc).include?(operator[:name]) ? "not(#{selected})" : selected

    else

      # For temporal ref. questions, need to convert dates to appropriate format in xpath.
      if ref_qing.temporal?
        format = :"javarosa_#{ref_qing.qtype_name}"
        formatted = Time.zone.parse(value).to_s(format)
        lhs = "format-date(#{lhs}, '#{Time::DATE_FORMATS[format]}')"
        rhs = "'#{formatted}'"
      else
        rhs = ref_qing.numeric? ? value : "'#{value}'"
      end

      "#{lhs} #{operator[:code]} #{rhs}"

    end
  end

  # Generates a human readable representation of condition.
  # prefs[:include_code] - Includes the question code in the string. May not always be desireable e.g. with printable forms.
  def to_s(prefs = {})
    if ref_qing_id.blank?
      '' # need to return something here to avoid nil errors
    else
      bits = []
      bits << Question.model_name.human
      bits << "##{ref_qing.rank}"
      bits << ref_qing.code if prefs[:include_code]

      if ref_qing.qtype_name == 'select_one'
        if ref_qing.multi_level?
          # Get the option level for the depth matching the number of options we have.
          level = ref_qing.level(options.size)
          raise "no option level found for depth = #{options.size} for condition #{id}" if level.nil?
          bits << level.name
          target = options.last.name
        else
          target = option.name
        end
      else
        target = option ? option.name : value
      end

      bits << I18n.t("condition.operators.#{op}")
      bits << (numeric_ref_question? ? target : "\"#{target}\"")
      bits.join(' ')
    end
  end

  def as_json(options = {})
    fields = %w(questioning_id ref_qing_id form_id op value option_ids)
    Hash[*fields.map{|k| [k, send(k)]}.flatten(1)]
  end

  def temporal_ref_question?
    ref_qing.try(:temporal?)
  end

  def numeric_ref_question?
    ref_qing.try(:numeric?)
  end

  private

    # Gets the referenced Subquestion.
    # If option_ids is not set, returns the first subquestion of ref_qing (just an alias).
    # If option_ids is set, uses the number of
    # option_ids in the array to determines the subquestion rank.
    def ref_subquestion
      ref_qing.subquestions[option_ids.blank? ? 0 : option_ids.size - 1]
    end

    def clear_blanks
      unless destroyed?
        self.value = nil if value.blank? || ref_qing && ref_qing.has_options?
        self.option_ids = nil if option_ids.blank? || ref_qing && !ref_qing.has_options?
      end
      return true
    end

    # Parses and reformats time strings given as conditions.
    def clean_times
      if !destroyed? && temporal_ref_question? && value.present?
        begin
          self.value = Time.zone.parse(value).to_s(:"std_#{ref_qing.qtype_name}")
        rescue ArgumentError
          self.value = nil
        end
      end
      return true
    end

    def all_fields_required
      errors.add(:base, :all_required) if any_fields_empty?
    end

    def any_fields_empty?
      ref_qing.blank? || op.blank? || (ref_qing.has_options? ? option_ids.blank? : value.blank?)
    end

    # copy mission from questioning
    def set_mission
      self.mission = questioning.try(:mission)
    end

end
