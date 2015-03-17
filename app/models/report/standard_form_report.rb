# when run, this report generates a fairly complex data structure, as follows:
# note: the elements in these arrays are not really hashes, but various types of objects
# StandardFormReport = {
#   :summary_collection => {
#     :subsets => [
#       {
#         :tag_groups => [
#           {
#             :tag => tag_object,
#             :type_groups => [
#               {
#                 :clusters => [
#                   {:summaries => [summary, summary, ...]},
#                   {:summaries => [summary, summary, ...]}
#                 ]
#               },
#               {
#                 :clusters => [
#                   {:summaries => [summary, summary, ...]},
#                   {:summaries => [summary, summary, ...]}
#                 ]
#               }
#             ]
#           }
#         ]
#       }
#     ]
#   }
# }
#
class Report::StandardFormReport < Report::Report
  # Form is set to destroy this report upon the Form's destruction.
  belongs_to(:form)

  # Questioning is set to nullify this association upon the Questioning's destruction.
  belongs_to(:disagg_qing, :class_name => 'Questioning')

  attr_reader :summary_collection, :response_count

  # question types that we leave off this report (stored as a hash for better performance)
  EXCLUDED_TYPES = {'location' => true}

  # options for the question_order attrib
  QUESTION_ORDER_OPTIONS = %w(number type)

  # question types that can be used to disaggregated
  DISAGGABLE_TYPES = %w(select_one)

  TEXT_RESPONSE_OPTIONS = %w(all short_only none)

  def as_json(options = {})
    # add the required methods to the methods option
    h = super(options)
    h[:response_count] = response_count
    h[:mission] = form.mission.as_json(:only => [:id, :name])
    h[:form] = form.as_json(:only => [:id, :name])
    h[:subsets] = subsets
    h[:observers_without_responses] = observers_without_responses.as_json(:only => [:id, :name])
    h[:disagg_question_id] = disagg_question_id
    h[:disagg_qing] = disagg_qing.as_json(:only => :id, :include => {:question => {:only => :code}})
    h[:no_data] = no_data?
    h
  end

  # current_ability - the ability under which the report should be run
  def run(current_ability)
    # make sure the disagg_qing is still on this form (unlikely to be an error)
    raise Report::ReportError.new("disaggregation question is not on this form") unless disagg_qing.nil? || disagg_qing.form_id == form_id

    # make sure disagg_qing is disaggable
    raise Report::ReportError.new("disaggregation question is incorrect type") unless can_disaggregate_with?(disagg_qing)

    # pre-calculate response count, accounting for user ability
    @response_count = form.responses.accessible_by(current_ability).count

    # determine if we should restrict the responses to a single user, or allow all
    restrict_to_user = current_ability.user.role(form.mission) == 'observer' ? current_ability.user : nil

    # generate summary collection (sets of disaggregated summaries)
    @summary_collection = Report::SummaryCollectionBuilder.new(questionings_to_include(form), disagg_qing,
      restrict_to_user: restrict_to_user).build

    # now tell each subset to group summaries by tag
    @summary_collection.subsets.each do |s|
      s.build_tag_groups(question_order: question_order || 'number', group_by_tag: group_by_tag)
    end

    @summary_collection
  end

  # returns all non-admin users in the form's mission with the given role that have not submitted any responses to the form
  # options[:role] - (symbol) the role to check for
  def users_without_responses(options)
    # eager load responses with users
    all_observers = form.mission.assignments.includes(:user).find_all{|a| a.role.to_sym == options[:role] && !a.user.admin?}.map(&:user)
    submitters = form.responses.includes(:user).map(&:user).uniq
    @users_without_responses = all_observers - submitters
  end

  def observers_without_responses
    users_without_responses(:role => :observer)
  end

  # returns the list of questionings to include in this report
  # takes an optional form argument to allow eager loaded form
  def questionings_to_include(form = nil)
    @questionings_to_include ||= (form || self.form).questionings.reject do |qing|
      qing.hidden? ||
      Report::StandardFormReport::EXCLUDED_TYPES[qing.qtype.name] ||
      text_responses == 'short_only' && qing.qtype.name == 'long_text' ||
      text_responses == 'none' && qing.qtype.textual?
    end
  end

  def empty?
    summary_collection.nil? || summary_collection.no_data?
  end

  # no_data is a more accurate name
  alias_method :no_data?, :empty?

  def exportable?
    false
  end

  def subsets
    summary_collection.try(:subsets)
  end

  def disagg_question_id
    disagg_qing.try(:question_id)
  end

  # settor method allowing the disaggregation *question* and not *questioning* to be set
  def disagg_question_id=(question_id)
    if question_id.nil?
      self.disagg_qing = nil
    else
      self.disagg_qing = form.questionings.detect{|qing| qing.question_id == question_id.to_i}
    end
  end

  # returns whether this report can be disaggregated by the given questioning
  def can_disaggregate_with?(qing)
    qing.nil? || DISAGGABLE_TYPES.include?(qing.question.qtype_name)
  end

end
