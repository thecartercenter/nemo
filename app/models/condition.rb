class Condition < ActiveRecord::Base
  include MissionBased, FormVersionable, Standardizable, Replicable

  # question types that cannot be used in conditions
  NON_REFABLE_TYPES = %w(location)

  belongs_to(:questioning, :inverse_of => :condition)
  belongs_to(:ref_qing, :class_name => "Questioning", :foreign_key => "ref_qing_id", :inverse_of => :referring_conditions)
  belongs_to(:option)

  before_validation(:clear_blanks)
  before_validation(:clean_times)
  before_create(:set_mission)

  validate(:all_fields_required)
  validates(:questioning, :presence => true)

  delegate :qtype, :form, :to => :questioning, :allow_nil => true
  delegate :has_options?, :select_options, :qtype, :rank, :to => :ref_qing, :prefix => :ref_question, :allow_nil => true

  OPS = [
    {:name => :eq, :types => %w(decimal integer text long_text address select_one datetime date time), :code => "="},
    {:name => :lt, :types => %w(decimal integer datetime date time), :code => "<"},
    {:name => :gt, :types => %w(decimal integer datetime date time), :code => ">"},
    {:name => :leq, :types => %w(decimal integer datetime date time), :code => "<="},
    {:name => :geq, :types => %w(decimal integer datetime date time), :code => "="},
    {:name => :neq, :types => %w(decimal integer text long_text address select_one datetime date time), :code => "!="},
    {:name => :inc, :types => %w(select_multiple), :code => "="},
    {:name => :ninc, :types => %w(select_multiple), :code => "!="}
  ]

  replicable :after_copy_attribs => :copy_ref_qing_and_option, :parent_assoc => :questioning, :dont_copy => [:ref_qing_id]

  # all questionings that can be referred to by this condition
  def refable_qings
    questioning ? questioning.previous.reject{|qing| %w[location].include?(qing.question.qtype.name)} : []
  end

  # all questionings that can be referred to by this condition
  def refable_qings
    questioning.previous.reject{|qing| NON_REFABLE_TYPES.include?(qing.qtype_name)}
  end

  # all referrable proto_questionings that have options
  def refable_qings_with_options
    refable_qings.reject{|qing| qing.options.nil?}
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
    ref_qing ? OPS.select{|o| o[:types].include?(ref_question_qtype.name)}.map{|o| o[:name]} : []
  end

  # duplicates this condition
  def duplicate
    self.class.new(:ref_qing_id => ref_qing_id, :op => op, :value => value, :option_id => option_id)
  end

  def verify_ordering
    raise ConditionOrderingError.new if questioning.rank <= ref_qing.rank
  end

  # gets the hash from the OPS array corresponding to self's operator
  def operator
    @operator ||= OPS.index_by{|o| o[:name]}[op.to_sym]
  end

  # returns all known operators
  def operators
    OPS
  end

  def to_odk
    # set default lhs
    lhs = "/data/#{ref_qing.odk_code}"

    if ref_question_has_options?
      xpath = "selected(#{lhs}, '#{option_id}')"
      xpath = "not(#{xpath})" if operator[:name] == :neq

    else
      # for numeric ref. questions, just convert value to string to get rhs
      if ref_question_qtype.numeric?
        rhs = value.to_s

      # for temporal ref. questions, need to convert dates to appropriate format
      elsif ref_question_qtype.temporal?

        # get xpath compatible date type name
        date_type = ref_question_qtype.name.gsub("datetime", "dateTime")
        format = :"javarosa_#{date_type.downcase}"
        formatted = Time.zone.parse(value).to_s(format)
        lhs = "format-date(#{lhs}, '#{Time::DATE_FORMATS[format]}')"
        rhs = "'#{formatted}'"

      # otherwise just quoted string
      else
        rhs = "'#{value}'"
      end

      # build the final xpath expression
      xpath = "#{lhs} #{operator[:code]} #{rhs}"
    end

    return xpath
  end

  def to_s
    words = I18n.t(op, :scope => [:condition, :operators])
    "#{Question.model_name.human} ##{ref_question_rank} #{words} \"#{option ? option.name : value}\""
  end

  # if options[:dropdown_values] is included, adds a series of lists of values for use with form dropdowns
  def as_json(options = {})
    fields = %w(questioning_id ref_qing_id op value option_id)
    fields += %w(refable_qing_types refable_qing_option_lists operators) if options[:dropdown_values]
    Hash[*fields.map{|k| [k, send(k)]}.flatten(1)]
  end

  private
    def clear_blanks
      # catch errors in case hash is frozen
      begin
        self.value = nil if value.blank? || ref_qing && ref_question_has_options?
        self.option = nil if option_id.blank? || ref_qing && !ref_question_has_options?
      rescue
      end
      return true
    end

    # parses and reformats time strings given as conditions
    def clean_times
      if ref_qing && !value.blank?
        begin
          # reformat only if it's a temporal question
          self.value = Time.zone.parse(value).to_s(:"std_#{ref_question_qtype.name}") if ref_question_qtype.temporal?
        rescue
          # reset to nil if error in parsing
          # catch additional error incase frozen hash
          (self.value = nil) rescue nil
        end
      end
      return true
    end

    def all_fields_required
      if ref_qing.blank? || op.blank? || ref_question_has_options? && option.blank? || !ref_question_has_options? && value.blank?
        errors.add(:base, :all_required)
      end
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
        replication.dest_obj.option = replication.dest_obj.ref_qing.question.option_set.optionings[ref_option_idx].option
      end
    end

    # copy mission from questioning
    def set_mission
      self.mission = questioning.try(:mission)
    end

end
