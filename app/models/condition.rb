class Condition < ActiveRecord::Base
  include MissionBased, FormVersionable, Standardizable, Replicable

  # question types that cannot be used in conditions
  NON_REFABLE_TYPES = %w(location)

  belongs_to(:questioning, inverse_of: :condition)
  belongs_to(:ref_qing, class_name: "Questioning", foreign_key: "ref_qing_id", inverse_of: :referring_conditions)

  before_validation(:clear_blanks)
  before_validation(:clean_times)
  before_create(:set_mission)

  validate(:all_fields_required)
  validates(:questioning, presence: true)

  delegate :qtype, :form, to: :questioning, allow_nil: true
  delegate :has_options?, :select_options, :qtype, :rank, :code, to: :ref_qing, prefix: :ref_question, allow_nil: true

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

  replicable after_copy_attribs: :copy_ref_qing_and_option, parent_assoc: :questioning, dont_copy: [:ref_qing_id]

  def options
    # We need to sort since ar#find doesn't guarantee order
    option_ids.nil? ? nil : Option.find(option_ids).sort_by{ |o| option_ids.index(o.id) }
  end

  # Temporary methods.
  def option_id
    option_ids.try(:first)
  end
  def option_id=(oid)
    self.option_ids = oid.nil? ? nil : "[#{oid}]"
  end
  def option
    option_ids.nil? ? nil : Option.find(option_ids.first)
  end
  def option=(o)
    self.option_ids = o.nil? ? nil : "[#{o.id}]"
  end

  # all questionings that can be referred to by this condition
  def refable_qings
    questioning ? questioning.previous.reject{|qing| %w[location].include?(qing.question.qtype.name)} : []
  end

  # all questionings that can be referred to by this condition
  def refable_qings
    questioning.previous.reject{|qing| NON_REFABLE_TYPES.include?(qing.qtype_name)}
  end

  # all referrable questionings that have options
  def refable_qings_with_options
    refable_qings.select{|qing| qing.has_options?}
  end

  # generates a hash mapping ids for refable questionings to their types
  def refable_qing_types
    Hash[*refable_qings.map{|qing| [qing.id, qing.qtype_name]}.flatten(1)]
  end

  # returns a hash mapping qing IDs to arrays of options (for select questions only), for use when choosing an option for the condition.
  def refable_qing_option_lists
    Hash[*refable_qings_with_options.map{|qing| [qing.id, qing.select_options]}.flatten(1)]
  end

  # returns names of all operators that are applicable to this condition based on its referred question
  def applicable_operator_names
    ref_qing ? OPERATORS.select{|o| o[:types].include?(ref_question_qtype.name)}.map{|o| o[:name]} : []
  end

  def verify_ordering
    raise ConditionOrderingError.new if questioning.rank <= ref_qing.rank
  end

  # Gets the definition of self's operator (self.op).
  def operator
    @operator ||= OPERATORS.detect{|o| o[:name] == op}
  end

  def to_odk
    lhs = "/data/#{ref_subquestion.odk_code}"

    if ref_question_has_options?

      selected = "selected(#{lhs}, '#{option_ids.last}')"

      # Apply negation if appropriate.
      %w(neq ninc).include?(operator[:name]) ? "not(#{selected})" : selected

    else

      # For temporal ref. questions, need to convert dates to appropriate format in xpath.
      if ref_question_qtype.temporal?
        format = :"javarosa_#{ref_question_qtype.name}"
        formatted = Time.zone.parse(value).to_s(format)
        lhs = "format-date(#{lhs}, '#{Time::DATE_FORMATS[format]}')"
        rhs = "'#{formatted}'"
      else
        rhs = ref_question_qtype.numeric? ? value : "'#{value}'"
      end

      "#{lhs} #{operator[:code]} #{rhs}"

    end
  end

  # generates a human readable representation of condition
  # options[:include_code] - includes the question code in the string. may not always be desireable e.g. with printable forms.
  def to_s(options = {})
    if ref_qing_id.blank?
      '' # need to return something here to avoid nil errors
    else
      words = I18n.t("condition.operators.#{op}")
      code = options[:include_code] ? " (#{ref_question_code})" : ''
      "#{Question.model_name.human} ##{ref_question_rank}#{code} #{words} \"#{option ? option.name : value}\""
    end
  end

  # if options[:dropdown_values] is included, adds a series of lists of values for use with form dropdowns
  def as_json(options = {})
    fields = %w(questioning_id ref_qing_id op value option_id)
    fields += %w(refable_qing_types refable_qing_option_lists operators) if options[:dropdown_values]
    Hash[*fields.map{|k| [k, send(k)]}.flatten(1)]
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
        self.value = nil if value.blank? || ref_qing && ref_question_has_options?
        self.option_ids = nil if option_ids.blank? || ref_qing && !ref_question_has_options?
      end
      return true
    end

    # Parses and reformats time strings given as conditions.
    def clean_times
      if !destroyed? && ref_qing && !value.blank? && ref_question_qtype.temporal?
        begin
          self.value = Time.zone.parse(value).to_s(:"std_#{ref_question_qtype.name}")
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
      ref_qing.blank? || op.blank? || (ref_question_has_options? ? option_ids.blank? : value.blank?)
    end

    # during replication process, copies the ref qing and option to the new condition
    def copy_ref_qing_and_option(replication)
      # the dest_obj's form is just the immediate parent (questioning)'s form
      dest_form = replication.parent.form

      # get the rank of the original ref_qing
      ref_qing_rank = self.ref_qing.rank

      # set the copy's ref_qing to the corresponding one
      replication.dest_obj.ref_qing = dest_form.questionings[ref_qing_rank - 1]

      if self.option
        # get the index of the original option
        ref_option_idx = self.ref_qing.question.option_set.options.index(self.option)

        # set the copy's option to the new ref_qing's corresponding option, in case the option set was also replicated
        replication.dest_obj.option = replication.dest_obj.ref_qing.question.option_set.options[ref_option_idx]
      end
    end

    # copy mission from questioning
    def set_mission
      self.mission = questioning.try(:mission)
    end

end
