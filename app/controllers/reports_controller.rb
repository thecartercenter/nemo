# frozen_string_literal: true

class ReportsController < ApplicationController
  include ReportEmbeddable

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

  def show
    respond_to do |format|
      format.html do
        run_or_fetch_and_handle_errors
        prepare_frontend_data(edit_mode: flash[:edit_mode])
        @report.record_viewing
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

  def report_params
    params.require(:report).permit(:type, :name, :form_id, :option_set_id, :display_type, :bar_style,
      :unreviewed, :filter, :question_labels, :show_question_labels, :question_order, :text_responses,
      :percent_type, :unique_rows, :calculations, :option_set, :mission_id, :mission,
      :disagg_question_id, :group_by_tag,
      option_set_choices_attributes: %i[id option_set_id _destroy],
      calculations_attributes: %i[id type attrib1_name question1_id arg1 attrib1 question1 rank _destroy])
  end
end
