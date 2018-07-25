module ResponseFactoryHelper
  # Returns a potentially nested array of answers.
  def self.build_answers(response, answer_values)
    root = response.build_root_node(type: "AnswerGroup", form_item: response.form.root_group, new_rank: 0, rank: 1, inst_num: 1)
    add_level(response.form.sorted_children, answer_values, root)
    root
  end

  def self.add_level(form_items, answer_values, parent)
    unless answer_values.nil?
      form_items.each_with_index do |item, i|
        answer_data = answer_values[i]
        unless answer_data.nil?
          case item
          when Questioning
            add_answer(parent, item, answer_values[i], i)
          when QingGroup
            add_group(parent, item, answer_values[i], i)
          # TODO handle repeating
          end
        end
      end
    end
    parent
  end

  def self.add_answer(parent, questioning, value, new_rank)
    if questioning.multilevel?
      build_answer_set(parent, questioning, value, new_rank)
    else
      parent.children.build(build_answer_attrs(parent, questioning, value, new_rank))
    end
  end

  def self.add_group(parent, form_group, answer_values, new_rank)
    answer_group = parent.children.build(
      type: "AnswerGroup",
      form_item: form_group,
      new_rank: new_rank,
      inst_num: new_rank,
      rank: new_rank + 1
    )
    add_level(form_group.c, answer_values, answer_group)
  end

  def self.build_answer_set(parent, qing, values, new_rank)
    set = parent.children.build(type: "AnswerSet", form_item: qing, new_rank: new_rank, inst_num: new_rank, rank: new_rank + 1)
    unless values.blank?
      options_by_name = qing.all_options.index_by(&:name)
      values.each do |v|
        option = qing.all_options.select { |o| o.canonical_name == v }.first
        option_id = option.present? ? option.id : nil
        set.children.build(
          type: "Answer",
          questioning: qing,
          option_id: option_id,
          new_rank: new_rank,
          inst_num: inst_num("Answer", parent),
          rank: new_rank + 1
        )
      end
    end
    set
  end

  def self.build_answer_attrs(parent, qing, value, new_rank)
    attrs = {
      type: "Answer",
      form_item: qing
    }
    attrs.merge!(rank_attributes("Answer", parent))
    case qing.qtype_name
    when "select_one" # not multilevel
      option = qing.all_options.select { |o| o.canonical_name == value }.first
      attrs[:option_id] = option.id
    when "select_multiple"
      options_by_name = qing.options.index_by(&:name)
      choices = value.map do |c|
        Choice.new(option: options_by_name[c]) || raise("could not find option with name '#{c}'")
      end
      attrs[:choices] = choices
    when "date", "time", "datetime"
      attrs["#{qing.qtype_name}_value"] = value
    when "image", "annotated_image", "signature", "sketch", "audio", "video"
      attrs[:media_object] = value
    else
      attrs[:value] = value
    end
    attrs
  end

  # Rank and inst_num will go away at end of answer refactor
  def self.rank_attributes(type, tree_parent)
    {
      new_rank: tree_parent.present? ? tree_parent.children.length : 0,
      rank: tree_parent.is_a?(AnswerSet) ? tree_parent.children.length + 1 : 1,
      inst_num: inst_num(type, tree_parent)
    }
  end

  # Inst num will go away at end of answer refactor; this makes it work with answer arranger
  def self.inst_num(type, tree_parent)
    if tree_parent.is_a?(AnswerGroupSet) # repeat group
      tree_parent.children.length + 1
    elsif %w[Answer AnswerSet AnswerGroupSet].include?(type)
      tree_parent.inst_num
    else
      1
    end
  end

  def self.build_answer(qing, value, new_rank)
    answers = case qing.qtype_name
    when "select_one"
      options_by_name = qing.all_options.index_by(&:name)
      values = value.nil? ? [nil] : Array.wrap(value)
      values.each_with_index.map do |v,i|
        Answer.new(
          questioning: qing,
          rank: i + 1,
          option: v.nil? ? nil : (options_by_name[v] or raise "could not find option with name '#{v}'")
        )
      end.shuffle

    # in this case, a should be an array of choice names
    when "select_multiple"
      options_by_name = qing.options.index_by(&:name)
      raise "expecting array answer value for question #{qing.code}, got #{value.inspect}" unless value.is_a?(Array)
      Answer.new(
        questioning: qing,
        choices:
          value.map { |c| Choice.new(option: options_by_name[c]) or raise "could not find option with name '#{c}'" }
      )

    when "date", "time", "datetime"
      Answer.new(questioning: qing, :"#{qing.qtype_name}_value" => value)
    when "image", "annotated_image", "signature", "sketch", "audio", "video"
      Answer.new(questioning: qing, media_object: value)
    else
      Answer.new(questioning: qing, value: value)
    end

    answers = Array.wrap(answers)
    answers.each { |a| a.inst_num = inst_num }
    answers
  end
end

FactoryGirl.define do
  factory :response do
    transient do
      answer_values []
    end

    user
    mission { get_mission }
    form { create(:form, :published, mission: mission) }
    source "web"

    trait :is_reviewed do
      transient do
        reviewer_name "Default"
      end
      reviewed true
      reviewer_notes { Faker::Lorem.paragraphs }
      reviewer { create(:user, name: reviewer_name) }
    end

    # Ensure unpublished form associations have been published at least once
    after(:build) do |response, evaluator|
      form = response.form
      unless form.published? && form.current_version.present?
        form.publish!
        form.unpublish!
      end
      # Build answer objects from answer_values array
      # Array may contain nils, which should result in answers with nil values.
      # Array may also contain recursively nested sub-arrays. Sub arrays may be given for:
      # - select_one questions with multilevel option sets
      # - select_multiple questions
      # - QingGroups
      if evaluator.answer_values
        ResponseFactoryHelper.build_answers(response, evaluator.answer_values)
      end
    end
  end
end
