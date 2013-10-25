class Report::StandardFormReport < Report::Report
  belongs_to(:form)

  attr_reader :groups, :summaries

  # question types that we leave off this report (stored as a hash for better performance)
  EXCLUDED_TYPES = {'location' => true}

  def as_json(options = {})
    # add the required methods to the methods option
    h = super(options)
    h[:response_count] = response_count
    h[:mission] = form.mission.as_json(:only => [:id, :name])
    h[:form] = form.as_json(:only => [:id, :name])
    h[:groups] = groups
    h[:observers_without_responses] = observers_without_responses.as_json(:only => [:id, :name])
    h
  end

  def run
    # eager load form
    f = Form.includes({:questionings => [
      # eager load qing conditions
      {:condition => [:ref_qing, :option]},

      # eager load referring conditions and their questionings
      {:referring_conditions => :questioning},

      # eager load questions and their option sets
      {:question => {:option_set => :options}},

      # eager load answers/responses (going to nix this later)
      {:answers => [:response, :option, {:choices => :option}]}
    ]}).find(form_id)

    # generate summaries
    @summaries = Report::QuestionSummary.generate_for(questionings_to_include(f))

    # divide summaries into clusters
    clusters = []
    @summaries.each do |s|
      # if this summary doesn't fit with the current cluster, or if there is no current cluster, create a new one
      if clusters.last && clusters.last.accepts(s)
        clusters.last.add(s)
      else
        clusters << Report::SummaryCluster.new(s)
      end
    end

    # create the main group
    @groups = [Report::SummaryGroup.new(:type => :all, :clusters => clusters)]
  end

  # returns the number of responses matching the report query
  def response_count
    @response_count ||= form.responses.count
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

  # returns the list of questionings to include in this report
  # takes an optional form argument to allow eager loaded form
  def questionings_to_include(form = nil)
    form ||= self.form
    form.questionings.reject do |qing|
      qing.hidden? || 
      Report::StandardFormReport::EXCLUDED_TYPES[qing.qtype.name] || 
      text_responses == 'short_only' && qing.qtype.name == 'long_text' ||
      text_responses == 'none' && qing.qtype.textual?
    end
  end

  def empty?
    response_count == 0
  end

  def exportable?
    false
  end
end
