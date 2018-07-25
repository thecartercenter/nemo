module ResponseFactoryHelper
  # Returns a potentially nested array of answers.
  def self.build_answers(response, answer_values)
    puts "response class: #{response.class}"
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
          #when QingGroup
            #add_group(parent, item, answer_values[i], i) # not repeating
          end
        end
      end
    end
    parent
  end

  def self.add_answer(parent, questioning, value, new_rank)
    parent.children.build(type: "Answer", form_item: questioning, value: value, new_rank: new_rank, rank: new_rank + 1, inst_num: parent.inst_num)

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
      puts "response class in after build: #{response.class}"
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
      ResponseFactoryHelper.build_answers(response, evaluator.answer_values)
    end
  end
end
