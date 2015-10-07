class ReportsController < ApplicationController
  include ReportEmbeddable
  include CsvRenderable

  # need to do special load for new/create/update because CanCan won't work with the STI hack in report.rb
  before_filter :custom_load, :only => [:create]

  # authorization via cancan
  load_and_authorize_resource :class => 'Report::Report'

  # Will do this explicitly below.
  skip_authorize_resource only: :data

  def index
    @reports = @reports.by_popularity
  end

  def new
    # make a default name in case the user wants to be lazy
    @report.generate_default_name

    # setup data to be used on client side
    # set edit mode if it was passed in the flash
    build_report_data(:edit_mode => flash[:edit_mode])

    render(:show)
  end

  def edit
    # set flash and redirect to show
    # we do it this way because staying in the edit action produces a somewhat inaccurate url
    flash[:edit_mode] = true
    show_report
  end

  def show
    # handle different formats
    respond_to do |format|
      # for html, use the render_show function below
      format.html do
        flash[:edit_mode] = false
        show_report
      end

      # for csv, just render the csv template
      format.csv do
        # run the report
        run_or_fetch_and_handle_errors
        raise "reports of this type are not exportable" unless @report.exportable?
        render_csv(@report.name.downcase)
      end
    end
  end

  def destroy
    destroy_and_handle_errors(@report)
    redirect_to(:action => :index)
  end

  # this method only reached through ajax
  def create
    @report.creator = current_user

    # if report is valid, save it and set flag (no need to run it b/c it will be redirected)
    @report.just_created = true if @report.errors.empty?

    # return data in json format
    build_report_data(:read_only => true)
    render(:json => @report_data.to_json)
  end

  # this method only reached through ajax
  def update
    # update the attribs
    @report.assign_attributes(report_params)

    # if report is not valid, can't run it
    if @report.valid?
      @report.save
      @report.reload # Without this, if you add a calculation and remove another on the same edit, the new one doesn't show.

      # re-run the report, handling errors
      run_or_fetch_and_handle_errors
    end

    # return data in json format
    build_report_data(:read_only => true)
    render(:json => @report_data.to_json)
  end

  # Executed via ajax. It just runs the report and returns the report_data json.
  def data
    authorize!(:read, @report)

    if params[:id].present?
      @report = Report::Report.find(params[:id])
      prepare_report(params[:edit_mode], params[:dashboard])

      render(:json => @report_data.to_json)
    end
  end

  # specify the class the this controller controls, since it's not easily guessed
  def model_class
    Report::Report
  end

  private
    # custom load method because CanCan won't work with STI hack in report.rb
    def custom_load
      @report = Report::Report.create(report_params.merge(:mission_id => current_mission.id))
    end

    def prepare_report(edit_mode, dashboard)
      unless @report.nil?
        authorize!(:read, @report)
        run_or_fetch_and_handle_errors
        if (dashboard == 'true')
          build_report_data(read_only: true, dont_set_title: true, user_can_edit: can?(:update, @report))
        else
          build_report_data(edit_mode: (edit_mode == 'true' ? true : false))
        end
      end
    end

    def show_report
      # record viewing of report
      @report.record_viewing

      # The data will be loaded via ajax
      render(:show)
    end

    def report_params
      params.require(:report).permit(:type, :name, :form_id, :option_set_id, :display_type, :bar_style, :unreviewed, :filter,
        :question_labels, :show_question_labels, :question_order, :text_responses, :percent_type, :unique_rows,
        :calculations, :option_set, :mission_id, :mission, :disagg_question_id, :group_by_tag,
        option_set_choices_attributes: [:option_set_id],
        calculations_attributes: [:id, :_destroy, :type, :report_report_id, :attrib1_name, :question1_id, :arg1, :attrib1, :question1, :rank])
    end
end
