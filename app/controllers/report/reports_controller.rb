class Report::ReportsController < ApplicationController
  # need to do special load for new/create/update because CanCan won't work with the STI hack in report.rb
  before_filter :custom_load, :only => [:create]
  
  # authorization via cancan
  load_and_authorize_resource
  
  def index
    # order by popularity and use 'becomes' to deal with inheritance
    @reports = @reports.by_popularity.all.collect{|r| r.becomes(Report::Report)}
  end
  
  def new
    # make a default name in case the user wants to be lazy
    @report.generate_default_name
    render_show
  end
  
  def show
    # prep the report for viewing
    init_report
    
    # handle different formats
    respond_to do |format|
      # for html, use the render_show function below
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
    begin flash[:success] = @report.destroy && "Report deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end    
  
  # this method only reached through ajax
  def create
    # if report is valid, save it and set flag (no need to run it b/c it will be redirected)
    @report.just_created = true if @report.errors.empty?
    
    # return data in json format
    render(:json => {:report => @report}.to_json)
  end

  # this method only reached through ajax
  def update
    # update the attribs
    @report.assign_attributes(params[:report])
    
    # if report is not valid, can't run it
    if @report.valid?
      # save
      @report.save
      # re-run the report, handling errors
      run_and_handle_errors
    end
    
    # return data in json format
    render(:json => {:report => @report}.to_json)
  end

  private
    # custom load method because CanCan won't work with STI hack in report.rb
    def custom_load
      @report = Report::Report.create(params[:report].merge(:mission_id => current_mission.id))
    end
  
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
      # setup json data to be used on client side
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
end
