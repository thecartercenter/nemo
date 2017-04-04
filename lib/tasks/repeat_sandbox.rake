task :repeat_sandbox => :environment do
  form = Form.find 9
  responses = form.responses
  puts ResponseCSV.new(responses)

  # form_id = 9
  # form = Form.find(form_id)
  # responses = form.responses
  # #data = []
  # responses.each do |r|
  #   puts "Response #{r.id} has #{r.answers.count} answers."
  #   non_repeat_answers = []
  #   repeat_answers = []
  #   r.answers.each do |a|
  #     is_repeat = a.questioning.parent_repeatable?
  #     answer = a.casted_value
  #     if !is_repeat
  #       non_repeat_answers << answer
  #     else
  #       repeat_answers << answer
  #     end
  #
  #     puts "Answer #{a.id} with answer #{answer} is repeat? #{is_repeat}"
  #   end
  #   response_rows = []
  #   repeat_answers.each do |r_a|
  #     response_row = ([form_id, r.id] + non_repeat_answers) << r_a
  #     response_rows << response_row
  #   end
  #   puts response_rows.inspect
  # end

end
