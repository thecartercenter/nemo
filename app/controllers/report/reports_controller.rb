class Report::ReportsController < ApplicationController
  def index
    @reports = apply_filters(Report::Report.by_popularity).all.collect{|r| r.becomes(Report::Report)}
  end
  
  def new
    @report = Report::Report.new_with_default_name(current_mission)
    render_show
  end
  
  def show
    @report = Report::Report.find(params[:id])
    init_report
    respond_to do |format|
      # for html, render the show action
      format.html{render_show}
      
      # for csv, just render the csv template
      format.csv do 
        # build a nice filename
        title = sanitize_filename(@report.name.gsub(" ", ""))
        render_csv(title)
      end
    end
  end
  
  def destroy
    @report = Report::Report.find(params[:id])
    begin flash[:success] = @report.destroy && "Report deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end    
  
  # only exec'd through json
  def create
    # attempt create the report
    @report = Report::Report.for_mission(current_mission).create(params[:report].merge(:mission_id => current_mission.id))

    # if report is valid, save it set flag (no need to run it b/c it will be redirected)
    @report.just_created = true if @report.errors.empty?
    
    # return data in json format
    render(:json => ajax_return_data.to_json)
  end

  # only exec'd through json
  def update
    # get/create the report
    @report = Report::Report.find(params[:id])
    # update the attribs
    @report.attributes = params[:report]
    
    # if report is not valid, can't run it
    if @report.valid?
      # save
      @report.save
      # re-run the report, handling errors
      run_and_handle_errors
    end
    
    # return data in json format
    render(:json => ajax_return_data.to_json)
  end

  private
    # sets up the report object by recording a viewing and running
    # returns true if report ran with no errors, false otherwise
    # should only be run if @report is not a new record
    def init_report
      raise if @report.new_record?
      
      # if not a new record, run it and record viewing
      @report.record_viewing
      
      return run_and_handle_errors
    end
    
    # runs the report and handles any errors, adding them to the report errors array
    # returns true if no errors, false otherwise
    def run_and_handle_errors
      begin
        @report.run
        return true
      rescue Report::ReportError, Search::ParseError
        @report.errors.add(:base, $!.to_s)
        return false
      end
    end
  
    # prepares and renders the show template, which is used for new and show actions
    def render_show
      # determine if user can edit form and save a flag
      @can_edit = authorized?(:action => "report_reports#update")
      
      # set json instance variable to be used in template
      @report_json = {
        :report => @report,
        :options => {
          :attribs => Report::AttribField.all,
          :forms => Form.for_mission(current_mission).with_form_type.all,
          :calculation_types => Report::Calculation.types,
          :questions => Question.for_mission(current_mission).includes(:forms, :type).all,
          :option_sets => OptionSet.for_mission(current_mission).all,
          :percent_types => Report::Report::PERCENT_TYPES
        }
      }.to_json
      
      render(:show)
    end
    
    def ajax_return_data
      {:report => @report}
    end
end
