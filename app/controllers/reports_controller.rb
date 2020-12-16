# frozen_string_literal: true

class ReportsController < ApplicationController
  # need to do special load for new/create/update because CanCan won't work with the STI hack in report.rb
  before_action :create_report, only: [:create]

  # authorization via cancan
  load_and_authorize_resource class: "Report::Report"

  # Will do this explicitly below.
  skip_authorize_resource only: :data

  def index
    @reports = @reports.by_popularity
  end

  def new
    @report.generate_default_name
    prepare_frontend_data
    render(:show)
  end

  def edit
    # set flash and redirect to show
    # we do it this way because staying in the edit action produces a somewhat inaccurate url
    flash[:edit_mode] = true
    redirect_to(report_path(@report))
  end

  # Only called via AJAX for the dashboard.
  def show
    respond_to do |format|
      format.html do
        run_or_fetch_and_handle_errors
        prepare_frontend_data(edit_mode: flash[:edit_mode], embedded_mode: request.xhr?)
        if request.xhr?
          render(partial: "reports/output_and_modal")
        else
          @report.record_viewing
        end
      end

      format.csv do
        authorize!(:export, @report)
        # run the report
        run_or_fetch_and_handle_errors(prefer_values: true, raise_errors: true)
        raise "reports of this type are not exportable" unless @report.exportable?
        render(csv: Report::CSVGenerator.new(report: @report), filename: @report.name.downcase)
      end
    end
  end

  def destroy
    destroy_and_handle_errors(@report)
    redirect_to(action: :index)
  end

  # Always reached through ajax
  def create
    render(json: {redirect_url: report_path(@report)})
  end

  # Always reached through ajax
  def update
    @report.update!(report_params)

    # Without this, if you add a calculation and remove another on the same edit, the new one doesn't show.
    @report.reload

    run_or_fetch_and_handle_errors
    prepare_frontend_data
    render(partial: "reports/output_and_modal")
  end

  # specify the class the this controller controls, since it's not easily guessed
  def model_class
    Report::Report
  end

  private

  def reports
    @decorated_reports ||= # rubocop:disable Naming/MemoizedInstanceVariableName
      ReportDecorator.decorate_collection(@reports)
  end
  helper_method :reports

  # custom load method because CanCan won't work with STI hack in report.rb
  def create_report
    # current_user or current_mission may be nil since this method runs before authorization.
    return unless current_user && current_mission
    @report = Report::Report.create!(report_params.merge(
      mission_id: current_mission.id,
      creator_id: current_user.id
    ))
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

  def report_params
    params.require(:report).permit(:type, :name, :form_id, :option_set_id, :display_type, :bar_style,
      :unreviewed, :filter, :question_labels, :show_question_labels, :question_order, :text_responses,
      :percent_type, :unique_rows, :calculations, :option_set, :mission_id, :mission,
      :disagg_question_id, :group_by_tag,
      option_set_choices_attributes: %i[id option_set_id _destroy],
      calculations_attributes: %i[id type attrib1_name question1_id arg1 attrib1 question1 rank _destroy])
  end
end
