# frozen_string_literal: true

# Methods for controllers that can render reports (ReportsController, dashboard)
module ReportEmbeddable
  extend ActiveSupport::Concern

  # Looks for a cached report object matching @report.
  # If one is found, stores it in @report. If not found,
  # calls run on the existing @report
  def run_or_fetch_and_handle_errors(prefer_values: false, raise_errors: false)
    @report = Rails.cache.fetch(cache_key_with_responses) do
      @report.run(current_ability, prefer_values: prefer_values)
      @report
    end
  rescue Report::ReportError, Search::ParseError => e
    raise_errors ? (raise e) : (@run_error = $ERROR_INFO.to_s)
  end

  def cache_key_with_responses
    [
      I18n.locale.to_s,

      # Need to include this because enumerators see only own data
      current_user.role(current_mission) == "enumerator" ? "enumerator-#{current_user.id}" : nil,

      Response.per_mission_cache_key(current_mission),
      @report.cache_key
    ].compact.join("-")
  end

  # sets up the @report_data structure which will be converted to json
  def prepare_frontend_data(**options)
    @report_data = {report: @report.as_json(methods: :errors)}.merge!(options)
    @report_data[:options] = prepare_form_options unless options[:embedded_mode]
    @report_data[:report][:generated_at] = I18n.l(Time.zone.now)
    @report_data[:report][:user_can_edit] = can?(:update, @report)
    @report_data[:report][:html] = report_html
    @report_data[:report][:error] = @run_error if @run_error
  end

  def report_html
    return nil if @run_error || @report.type != "Report::StandardFormReport"
    form_type = @report.model_name.singular_route_key.remove(/^report_/)
    render_to_string(partial: "reports/#{form_type}/display")
  end

  def prepare_form_options
    {
      attribs: Report::AttribField.all,
      forms: Form.for_mission(current_mission).by_name.as_json(only: %i[id name]),
      calculation_types: Report::Calculation::TYPES,
      questions: Question.for_mission(current_mission).with_type_property(:reportable)
        .includes(:forms, :option_set).by_code.as_json(only: %i[id code qtype_name],
                                                       methods: %i[form_ids geographic?]),
      option_sets: OptionSet.for_mission(current_mission).by_name.as_json(only: %i[id name]),
      percent_types: Report::Report::PERCENT_TYPES,

      # the names of qtypes that can be used in headers
      headerable_qtype_names: QuestionType.all.select(&:headerable?).map(&:name)
    }
  end
end
