class RemoveObservedAtFromResponses < ActiveRecord::Migration[4.2]
  def up
    # wrap this part in a transaction in case it fails for some reason
    transaction do
      # if there are any existing forms
      if Form.count > 0
        # add a new question called Form Start Time
        puts "Creating new FormStartTime question"
        datetime_type = QuestionType.find_by_name("datetime")
        newq = Question.create!(:code => "FormStartTime", :question_type_id => datetime_type.id, :name_en => "Form Start Time",
          :hint_en => "The time at which the form was started. Copied from the old 'Observation Time' field.")

        # for each form
        Form.all.each do |form|
          puts "Updating responses for form: '#{form.name}'"
          # add the question to the form
          qing = form.questionings.create!(:question => newq)

          # for each response, copy the value of observed_at to the new question
          form.responses.each do |resp|
            if resp.respond_to?(:answers)
              resp.answers.create!(:questioning => qing, :datetime_value => resp.observed_at)
            end
          end
        end
      end
    end

    # remove the column
    puts "Finished updating responses. Proceeding with removal of observed_at column."
    remove_column :responses, :observed_at
  end

  def down
  end
end
