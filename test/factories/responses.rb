def find_question_by_code(code)
  question = Question.where(:code => code).first
end

def find_option_by_name(name)
  option = Option.where("_name" => name).first
end

FactoryGirl.define do
  factory :response do
    ignore do
      _answers []
    end

    user
    form
    mission { get_mission }

    # build answer objects from _answers array
    answers do
      _answers.each_with_index.map do |a, idx|
        # build answer from string value
        qing = form.questionings[idx]
        ans = Answer.new(:questioning => qing)

        unless a.nil?
          case qing.qtype_name

          when 'select_one'
            if a.nil?
              ans.option_id = nil
            else
              option = qing.options.index_by(&:name)[a] or raise "could not find option with name '#{a}'"
              ans.option_id = option.id
            end

          # in this case, a should be either nil or an array of arrays of choice names
          when 'select_multiple'
            # if a is nil, we can just do nothing
            unless a.nil?
              options_by_name = qing.options.index_by(&:name)
              ans.choices = a.map do |c|
                option = options_by_name[c] or raise "could not find option with name '#{c}'"
                Choice.new(:option_id => option.id)
              end
            end

          when 'date'
            ans.date_value = a

          when 'time'
            ans.time_value = a

          when 'datetime'
            ans.datetime_value = a

          else
            ans.value = a
          end
        end
        ans
      end
    end
  end

  FactoryGirl.define do
    # this factory was created by Tim Hui for duplicate testing and should be refactored into the above later
    factory :response_for_duplicate_testing do

      # if no answer_names are submitted, just make it an empty object
      ignore do
        answer_names {}
      end

      user {get_user}
      form

      # create answers for each answer_name submitted with given
      # question code and value
      answers {
        if answer_names
          answers = answer_names.each_with_index.map {
            |(k,v),i|

            # find the question by given key
            question = find_question_by_code(k)

            # find that question's associated options and locate option with the given value, else option is null
            option = question.options ? question.options.find{|o| o.name_en == v} : nil

            # if the question's question type is text, set text value value to v.
            value = question.qtype_name == "text" ? v : nil

            # set questioning to questioning within question where form id is the one passed in
            questioning = question.questionings.where(:form_id => form.id).first

            # for each answer in string format, create an Answer
            # using option or value, and a questioning
            a = Answer.new(
              :option => option,
              :value => value,
              :questioning => questioning
            )

            # if value is an array, the answer submitted consists of choice(s)
            if v.kind_of?(Array)
              choices = Array.new
              v.each do |c|
                a.choices << Choice.new(:option => find_option_by_name(c))
              end
            end
            a
          }
        end

        answers
      }

      before(:create) do |o,e|
        e.generate_duplicate_signature
      end
    end
  end
end