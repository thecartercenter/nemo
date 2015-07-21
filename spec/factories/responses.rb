module ResponseFactoryHelper
  # Returns a potentially nested array of answers.
  def self.build_answers(parent, values)
    parent.children.each_with_index.map do |item, i|
      if i < values.size
        value = values[i]
        if item.is_a?(QingGroup)
          raise "expecting array of answer values for #{item.group_name}, got #{value.inspect}" unless value.is_a?(Array)
          build_answers(item, value)
        else
          build_answer(item, value)
        end
      else
        nil
      end
    end
  end

  def self.build_answer(qing, value)
    case qing.qtype_name
    when 'select_one'
      options_by_name = qing.all_options.index_by(&:name)
      values = value.nil? ? [nil] : Array.wrap(value)
      values.each_with_index.map do |v,i|
        Answer.new(
          questioning: qing,
          rank: values.size > 1 ? i + 1 : nil,
          option: v.nil? ? nil : (options_by_name[v] or raise "could not find option with name '#{v}'")
        )
      end.shuffle

    # in this case, a should be an array of choice names
    when 'select_multiple'
      options_by_name = qing.options.index_by(&:name)
      raise "expecting array answer value for question #{qing.code}, got #{value.inspect}" unless value.is_a?(Array)
      Answer.new(
        questioning: qing,
        choices: value.map{ |c| Choice.new(option: options_by_name[c]) or raise "could not find option with name '#{c}'" }
      )

    when 'date', 'time', 'datetime'
      Answer.new(questioning: qing, :"#{qing.qtype_name}_value" => value)

    else
      Answer.new(questioning: qing, value: value)
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
    form { create(:form, :mission => mission) }
    source 'web'

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
