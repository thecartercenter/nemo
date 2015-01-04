FactoryGirl.define do
  factory :response do
    ignore do
      answer_values []
    end

    user
    mission { get_mission }
    form { create(:form, :mission => mission) }
    source 'web'

    # Build answer objects from answer_values array
    # Array may contain nils, which should result in answers with nil values.
    answers do
      answer_values.each_with_index.map do |value, idx|
        qing = form.questionings[idx]
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
          Answer.new(
            questioning: qing,
            choices: value.map{ |c| Choice.new(option: options_by_name[c]) or raise "could not find option with name '#{c}'" }
          )

        when 'date', 'time', 'datetime'
          Answer.new(questioning: qing, :"#{qing.qtype_name}_value" => value)

        else
          Answer.new(questioning: qing, value: value)
        end
      end.flatten
    end

  end
end
