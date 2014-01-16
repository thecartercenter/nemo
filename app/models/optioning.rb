class Optioning < ActiveRecord::Base
  include MissionBased, FormVersionable, Standardizable, Replicable, OptioningParentable

  belongs_to(:option, :inverse_of => :optionings)
  belongs_to(:option_set, :inverse_of => :all_optionings)
  belongs_to(:option_level, :inverse_of => :optionings)
  belongs_to(:parent, :class_name => 'Optioning')

  # this association gets the children of this optioning
  has_many(:optionings, :order => "rank", :foreign_key => :parent_id)

  before_create(:set_mission)
  before_destroy(:no_answers_or_choices)

  validate(:must_have_parent_if_not_top_option_level)
  validate(:must_have_option_level_if_in_multi_level_option_set)

  accepts_nested_attributes_for(:option)

  # option level rank
  delegate :rank, :to => :option_level, :allow_nil => true, :prefix => true

  # replication options
  replicable :child_assocs => :option, :parent_assoc => :option_set

  # temp var used in the option_set form
  attr_writer :included

  def included
    # default to true
    defined?(@included) ? @included : true
  end

  # looks for answers and choices related to this option setting
  def has_answers_or_choices?
    !option_set.questions.detect{|q| q.questionings.detect{|qing| qing.answers.detect{|a| a.option_id == option_id || a.choices.detect{|c| c.option_id == option_id}}}}.nil?
  end

  def no_answers_or_choices
    raise DeletionError.new(:cant_delete_if_has_response) if has_answers_or_choices?
  end

  def removable?
    !has_answers_or_choices?
  end

  def as_json(options = {})
    if options[:for_option_set_form]
      super(:only => :id, :methods => :removable?).merge(:option => option.as_json(:for_option_set_form => true))
    else
      super(options)
    end
  end

  # returns a string representation of this node and its children, indented by the given amount
  # options[:space] - the number of spaces to indent
  def to_s_indented(options = {})
    options[:space] ||= 0
    (' ' * options[:space]) +
      ["(#{option_level.try(:name)})", "#{rank}. #{option.name}\n"].compact.join(' ') +
      optionings.map{|c| c.to_s_indented(:space => options[:space] + 2)}.join
  end

  private

    # copy mission from option_set
    def set_mission
      self.mission = option_set.try(:mission)
    end

    def must_have_parent_if_not_top_option_level
      errors.add(:parent_id, "can't be blank if not top option level") if option_level_rank.present? && option_level_rank > 1 && parent_id.nil?
    end

    def must_have_option_level_if_in_multi_level_option_set
      # if this optioning has a parent, or if it's a top level optioning in a multi level set, then must have an option level
      if (option_set.present? && option_set.multi_level? || parent.present?) && option_level_id.blank?
        errors.add(:option_level_id, "can't be blank if in multilevel option set")
      end
    end
end
