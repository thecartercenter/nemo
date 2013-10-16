class Report::StandardFormReport < Report::Report
  belongs_to(:form)

  # question types that we leave off this report (stored as a hash for better performance)
  EXCLUDED_TYPES = {'location' => true}

  def as_json(options = {})
    # add the required methods to the methods option
    options[:methods] = Array.wrap(options[:methods]) + [:response_count, :summaries, :observers_without_responses]
    h = super(options)
  end

  # returns the number of responses matching the report query
  def response_count
    @response_count ||= form.responses.count
  end

  # returns an array of question summaries ordered by question rank
  def summaries
    return @summaries if @summaries

    # eager load form
    f = Form.includes({:questionings => [{:question => {:option_set => :options}}, 
      {:answers => [:response, :option, {:choices => :option}]}]}).find(form_id)

    # generate
    @summaries = f.questionings.reject{|qing| qing.hidden? || EXCLUDED_TYPES[qing.qtype.name]}.map do |qing|
      Report::QuestionSummary.new(:questioning => qing)
    end
  end

  # returns all non-admin users in the form's mission with the given (active) role that have not submitted any responses to the form
  # options[:role] - (symbol) the role to check for
  def users_without_responses(options)
    # eager load responses with users
    all_observers = form.mission.assignments.includes(:user).find_all{|a| a.role.to_sym == options[:role] && a.active? && !a.user.admin?}.map(&:user)
    submitters = form.responses.includes(:user).map(&:user).uniq
    @users_without_responses = all_observers - submitters
  end

  def observers_without_responses
    users_without_responses(:role => :observer)
  end

  def empty?
    response_count == 0
  end

  def exportable?
    false
  end
end
