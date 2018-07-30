# An non repeat answer group is an array of answer values or answer groups
# A repeat answer group is a hash with the key :repeating whose value is an array of answer group instances
#Example answer_values with nested repeat groups:
# root:               [
# AnswerGroup          [
# Answer                1
#                      ],
# Answer               create(:media_image),
# Answer               %w[Plant Oak],
# Outer repeat grp    {repeating: [
# Outer grp instance1   [
# Answer                 2,
# Inner rpt grp          {repeating: [
# Inner rpt grp instance1 [
# Answer                   3
#                         ]
#                        ]}
#                       ]
#                     ]}
#                    ]


module ResponseFactoryHelper
  # Returns a potentially nested array of answers.
  def self.build_answers(response, answer_values)
    root = response.build_root_node({type: "AnswerGroup", form_item: response.form.root_group}
      .merge(rank_attributes("AnswerGroup", nil)))
    add_level(response.form.sorted_children, answer_values, root)
    root
  end

  def self.add_level(form_items, answer_values, parent)
    unless answer_values.nil?
      form_items.each_with_index do |item, i|
        answer_data = answer_values[i]
        next if answer_data.nil?
        case item
        when Questioning
          add_answer(parent, item, answer_data)
        when QingGroup
          puts "answer data: #{answer_data}"
          puts "repeatable? #{item.repeatable?}"
          puts "answer_data is a #{answer_data.class}"
          puts "is a hash: #{answer_data.is_a?(Hash)}"
          puts "has key repeating: #{answer_data.key?(:repeating)}" if answer_data.is_a?(Hash)
          if item.repeatable? && answer_data.is_a?(Hash) && answer_data.key?(:repeating)
            add_group_set(item, answer_data, parent)
          else
            add_group(item, answer_data, parent)
          end
        end
      end
    end
    parent
  end

  def self.add_group_set(form_group, values, parent)
    pp form_group
    puts "add group set: #{values}"
    values = values[:repeating]
    group_set = parent.children.build({
      type: "AnswerGroupSet",
      form_item: form_group
    }.merge(rank_attributes("AnswerGroupSet", parent)))
    puts "values: #{values}"
    values.each do |group_instance_values| # each array represents one group
      puts "value: #{group_instance_values}"
      add_group(form_group, group_instance_values, group_set)
    end
  end

  def self.add_answer(parent, questioning, value)
    puts "add answer: #{value}"
    if questioning.multilevel?
      build_answer_set(parent, questioning, value)
    else
      parent.children.build(build_answer_attrs(parent, questioning, value))
    end
  end

  def self.add_group(form_group, answer_values, parent)
    puts "add group: #{answer_values}"
    answer_group = parent.children.build({type: "AnswerGroup", form_item: form_group}
      .merge(rank_attributes("AnswerGroup", parent)))
    add_level(form_group.c, answer_values, answer_group)
  end

  def self.build_answer_set(parent, qing, values)
    "build answer set: #{values}"
    set = parent.children.build({type: "AnswerSet", form_item: qing}
      .merge(rank_attributes("AnswerSet", parent)))
    if values.present?
      options_by_name = qing.all_options.index_by(&:name)
      values.each do |v|
        unless v.blank?
          option = qing.all_options.select { |o| o.canonical_name == v }.first
          option_id = option.present? ? option.id : nil
          set.children.build(
            {
              type: "Answer",
              questioning: qing,
              option_id: option_id
            }.merge(rank_attributes("Answer", set))
          )
        end
      end
    end
    set
  end

  def self.build_answer_attrs(parent, qing, value)
    attrs = {
      type: "Answer",
      form_item: qing
    }
    attrs.merge!(rank_attributes("Answer", parent))
    case qing.qtype_name
    when "select_one" # not multilevel
      unless value.blank?
        option = qing.all_options.select { |o| o.canonical_name == value }.first
        attrs[:option_id] = option.id
      end
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
