module ResponseFactoryHelper
  # Returns a potentially nested array of answers.
  def self.build_answers(parent, values, inst_num = 1)
    parent.children.each_with_index.map do |item, i|
      if i < values.size
        value = values[i]
        if item.is_a?(QingGroup)
          unless value.is_a?(Array)
            raise "expecting array of answer values for #{item.group_name}, got #{value.inspect}"
          end

          # If first element of array is :repeating, remove it, leaving an array of answer groups.
          # Otherwise, wrap value in array to get an array of answer groups, but with only one element.
          answer_groups = if value.first == :repeating
            value[1..-1]
          else
            [value]
          end

          answer_groups.each_with_index.map { |answer_group, i| build_answers(item, answer_group, i + 1) }
        else
          build_answer(item, value, inst_num)
        end
      end
    end.flatten
  end

  def self.build_answer(qing, value, inst_num)
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
    after(:build) do |response|
      form = response.form
      unless form.published? && form.current_version.present?
        form.publish!
        form.unpublish!
      end
    end

    # Build answer objects from answer_values array
    # Array may contain nils, which should result in answers with nil values.
    # Array may also contain recursively nested sub-arrays. Sub arrays may be given for:
    # - select_one questions with multilevel option sets
    # - select_multiple questions
    # - QingGroups
    answers do
      ResponseFactoryHelper.build_answers(form.root_group, answer_values).flatten.compact
    end
  end
end
