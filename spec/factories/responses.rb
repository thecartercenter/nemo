module ResponseFactoryHelper

  def self.build_answers(response, answer_values)
    puts "answer values: #{answer_values}"
    root = AnswerGroup.new(questioning_id: response.form.root_group.id)
    add_level(response.form.sorted_children, answer_values, root)
    root
  end

  def self.add_level(form_items, answer_values, parent)
    unless answer_values.blank?
      form_items.each_with_index do |item, i|
        answer_data = answer_values[i]
        unless answer_data.nil?
          case item
          when Questioning
            parent.children << new_answer(item, answer_values[i], i)
          when QingGroup
            parent.children << new_group(item, answer_values[i], i) #not repeating
          end
        end
      end
    end
    parent
  end

  def self.new_group(form_group, answer_values, new_rank)
    group = AnswerGroup.new(
      questioning_id: form_group.id,
      new_rank: new_rank,
      inst_num: new_rank,
      rank: new_rank + 1
    )
    add_level(form_group.c, answer_values, group)
  end

  def self.new_answer(questioning, value, new_rank)
    build_answer(questioning, value, new_rank)
  end
  # Returns a potentially nested array of answers.
  # def self.build_answers(parent, values, inst_num = 1)
  #   parent.sorted_children.each_with_index.map do |item, i|
  #     if i < values.size
  #       value = values[i]
  #       if item.is_a?(QingGroup)
  #         next if value.nil?
  #         unless value.is_a?(Array)
  #           raise "expecting array of answer values for #{item.group_name}, got #{value.inspect}"
  #         end
  #
  #         # If first element of array is :repeating, remove it, leaving an array of answer groups.
  #         # Otherwise, wrap value in array to get an array of answer groups, but with only one element.
  #         answer_groups = if value.first == :repeating
  #           value[1..-1]
  #         else
  #           [value]
  #         end
  #
  #         answer_groups.each_with_index.map { |answer_group, i| build_answers(item, answer_group, i + 1) }
  #       else
  #         build_answer(item, value, inst_num)
  #       end
  #     end

  #   end.flatten
  # end

  # def self.build_answer_tree(response, form, values)
  #   root = AnswerGroup.create!(form_item: form.root_group, response: response, inst_num: 1)
  #   add_level(form.root_group.sorted_children, root, values)
  #   response.associate_tree(root)
  # end
  #
  # def self.add_level(form_nodes, answer_tree_parent, values)
  #   form_nodes.each_with_index do |form_node, i|
  #     answer = build_answer(form_node, values[i], answer_tree_parent.inst_num)
  #     answer_tree_parent.children << answer
  #   end
  # end
  #
  def self.build_answer(qing, value, new_rank)
    a = nil
    puts qing.qtype_name
    case qing.qtype_name
    when "select_one"
      if qing.multilevel?
        set = AnswerSet.new(questioning_id: qing.id, new_rank: new_rank, inst_num: new_rank, rank: new_rank + 1)
        unless value.blank?
          options_by_name = qing.all_options.index_by(&:name)
          value.each do |v|
            option = qing.all_options.select { |o| o.canonical_name == v }.first
            option_id = option.present? ? option.id : nil
            set.children << Answer.new(
              questioning: qing,
              option_id: option_id,
              new_rank: new_rank,
              inst_num: new_rank,
              rank: new_rank + 1
            )
          end
        end
        set.debug_tree
        return set
      else
        option = qing.all_options.select{ |o| o.canonical_name == value }.first
        a = Answer.new(
          questioning: qing,
          option_id: option.id
        )
      end

    # when "select_one"
    #   options_by_name = qing.all_options.index_by(&:name)
    #   values = value.nil? ? [nil] : Array.wrap(value)
    #   values.each_with_index.map do |v,i|
    #     Answer.new(
    #       questioning: qing,
    #       rank: i + 1,
    #       option: v.nil? ? nil : (options_by_name[v] or raise "could not find option with name '#{v}'"),
    #       new_rank: new_rank
    #     )
    #   end.shuffle

    # in this case, a should be an array of choice names
    when "select_multiple"
      options_by_name = qing.options.index_by(&:name)
      raise "expecting array answer value for question #{qing.code}, got #{value.inspect}" unless value.is_a?(Array)
      a = Answer.new(
        questioning: qing,
        choices:
          value.map { |c| Choice.new(option: options_by_name[c]) or raise "could not find option with name '#{c}'" }
      )

    when "date", "time", "datetime"
      a = Answer.new(questioning: qing, :"#{qing.qtype_name}_value" => value)
    when "image", "annotated_image", "signature", "sketch", "audio", "video"
      a = Answer.new(questioning: qing, media_object: value)
    else
      puts "make a regular answer:"
      a = Answer.new(questioning: qing, value: value)
    end
    a.new_rank = new_rank
    a.inst_num = 1
    a.rank = 1# new_rank + 1
    a
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
    after(:create) do |response, evaluator|
      puts "after create"
      form = response.form
      unless form.published? && form.current_version.present?
        form.publish!
        form.unpublish!
      end
      answer_tree = ResponseFactoryHelper.build_answers(response, evaluator.answer_values)
      response.associate_tree(answer_tree)
      response.reload
    end

    # Build answer objects from answer_values array
    # Array may contain nils, which should result in answers with nil values.
    # Array may also contain recursively nested sub-arrays. Sub arrays may be given for:
    # - select_one questions with multilevel option sets
    # - select_multiple questions
    # - QingGroups
    # answers do
    #   if answer_values.nil?
    #     []
    #   else
    #     ResponseFactoryHelper.build_answer_tree(response, form.root_group, answer_values, 1).flatten.compact
    #   end
    # end
  end
end
