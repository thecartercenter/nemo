# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: report_reports
#
#  id               :uuid             not null, primary key
#  aggregation_name :string(255)
#  bar_style        :string(255)      default("side_by_side")
#  display_type     :string(255)      default("table")
#  filter           :text
#  group_by_tag     :boolean          default(FALSE), not null
#  name             :string(255)      not null
#  percent_type     :string(255)      default("none")
#  question_labels  :string(255)      default("title")
#  question_order   :string(255)      default("number"), not null
#  text_responses   :string(255)      default("all")
#  type             :string(255)      not null
#  unique_rows      :boolean          default(FALSE)
#  unreviewed       :boolean          default(FALSE)
#  view_count       :integer          default(0), not null
#  viewed_at        :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  creator_id       :uuid
#  disagg_qing_id   :uuid
#  form_id          :uuid
#  mission_id       :uuid             not null
#
# Indexes
#
#  index_report_reports_on_creator_id      (creator_id)
#  index_report_reports_on_disagg_qing_id  (disagg_qing_id)
#  index_report_reports_on_form_id         (form_id)
#  index_report_reports_on_mission_id      (mission_id)
#  index_report_reports_on_view_count      (view_count)
#
# Foreign Keys
#
#  report_reports_creator_id_fkey      (creator_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#  report_reports_disagg_qing_id_fkey  (disagg_qing_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#  report_reports_form_id_fkey         (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#  report_reports_mission_id_fkey      (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

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
  belongs_to(:disagg_qing, class_name: "Questioning")

  attr_reader :summary_collection, :response_count

  # question types that we leave off this report (stored as a hash for better performance)
  EXCLUDED_TYPES = {
    "location" => true,
    "image" => true,
    "annotated_image" => true,
    "signature" => true,
    "sketch" => true,
    "video" => true,
    "audio" => true
  }.freeze

  # options for the question_order attrib
  QUESTION_ORDER_OPTIONS = %w[number type].freeze

  # question types that can be used to disaggregated
  DISAGGABLE_TYPES = %w[select_one].freeze

  TEXT_RESPONSE_OPTIONS = %w[all short_only none].freeze

  # How many non reporting enumerators it will show on the report before summarizing the rest
  MISSING_OBSERVERS_SIZE_LIMIT = 100

  def as_json(options = {})
    # add the required methods to the methods option
    h = super(options)
    h[:response_count] = response_count
    h[:mission] = form.mission.as_json(only: %i[id name])
    h[:form] = form.as_json(only: %i[id name])
    h[:subsets] = subsets
    h[:enumerators_without_responses] = enumerators_without_responses.as_json(only: %i[id name])
    h[:disagg_question_id] = disagg_question_id
    h[:disagg_qing] = disagg_qing.as_json(only: :id, include: {question: {only: :code}})
    h[:no_data] = no_data?
    h[:raw_answer_limit] = Report::SummaryCollectionBuilder::RAW_ANSWER_LIMIT
    h
  end

  # current_ability - the ability under which the report should be run
  def run(current_ability, _options = {})
    # make sure the disagg_qing is still on this form (unlikely to be an error)
    unless disagg_qing.nil? || disagg_qing.form_id == form_id
      raise Report::ReportError, "disaggregation question is not on this form"
    end

    # make sure disagg_qing is disaggable
    unless can_disaggregate_with?(disagg_qing)
      raise Report::ReportError, "disaggregation question is incorrect type"
    end

    # pre-calculate response count, accounting for user ability
    @response_count = form.responses.accessible_by(current_ability).count

    # determine if we should restrict the responses to a single user, or allow all
    restrict_to_user = current_ability.user.role(form.mission) == "enumerator" ? current_ability.user : nil

    # generate summary collection (sets of disaggregated summaries)
    @summary_collection = Report::SummaryCollectionBuilder.new(questionings_to_include(form), disagg_qing,
      restrict_to_user: restrict_to_user).build

    # now tell each subset to group summaries by tag
    @summary_collection.subsets.each do |s|
      s.build_tag_groups(question_order: question_order || "number", group_by_tag: group_by_tag)
    end

    @summary_collection
  end

  # Returns all non-admin users in the form's mission with the given role that have
  # not submitted any responses to the form
  #
  # options[:role] the role to check for
  # options[:limit] how many users we want to fetch from the db
  def users_without_responses(options)
    User.without_responses_for_form(form, options)
  end

  def enumerators_without_responses
    users = users_without_responses(role: :enumerator, limit: MISSING_OBSERVERS_SIZE_LIMIT)

    if users.empty?
      I18n.t("report/report.zero_missing_enumerators")
    else
      truncated = false
      if users.size > MISSING_OBSERVERS_SIZE_LIMIT
        users.slice!(MISSING_OBSERVERS_SIZE_LIMIT..-1)
        truncated = true
      end
      names = users.map(&:name).join(", ")
      truncation_msg = truncated ? ", ... (#{I18n.t('common.clipped')})" : ""
      "#{names}#{truncation_msg}"
    end
  end

  # returns the list of questionings to include in this report
  # takes an optional form argument to allow eager loaded form
  def questionings_to_include(form = nil)
    @questionings_to_include ||= (form || self.form).questionings.reject do |qing|
      qing.disabled? ||
        Report::StandardFormReport::EXCLUDED_TYPES[qing.qtype.name] ||
        text_responses == "short_only" && qing.qtype.name == "long_text" ||
        text_responses == "none" && qing.qtype.textual?
    end
  end

  def empty?
    summary_collection.nil? || summary_collection.no_data?
  end

  # no_data is a more accurate name
  alias no_data? empty?

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
    self.disagg_qing = if question_id.nil?
                         nil
                       else
                         form.questionings.detect { |qing| qing.question_id == question_id }
                       end
  end

  # returns whether this report can be disaggregated by the given questioning
  def can_disaggregate_with?(qing)
    qing.nil? || DISAGGABLE_TYPES.include?(qing.question.qtype_name)
  end

  def references?
    form.enabled_questionings.any? { |qing| qing.reference.present? }
  end
end
