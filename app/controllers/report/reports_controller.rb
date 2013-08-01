class Report::ReportsController < ApplicationController
  include ReportEmbeddable
  
  # need to do special load for new/create/update because CanCan won't work with the STI hack in report.rb
  before_filter :custom_load, :only => [:create]
  
  # authorization via cancan
  load_and_authorize_resource
  
  def index
    @reports = @reports.by_popularity
  end
  
  def new
    # make a default name in case the user wants to be lazy
    @report.generate_default_name
    render_show
  end
  
  def edit
    redirect_to(:action => :show)
  end
  
  def show
    # run the report
    run_and_handle_errors
    
    # handle different formats
    respond_to do |format|
      # for html, use the render_show function below
      format.html do 
        # record viewing of report
        @report.record_viewing

        render_show
      end
      
      # for csv, just render the csv template
      format.csv do 
        # build a nice filename
        title = sanitize_filename(@report.name.gsub(" ", ""))
        render_csv(title)
      end
    end
  end
  
  def destroy
    destroy_and_handle_errors(@report)
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
  
  protected
    # specify the class the this controller controls, since it's not easily guessed
    def model_class
      Report::Report
    end

  private
    # custom load method because CanCan won't work with STI hack in report.rb
    def custom_load
      @report = Report::Report.create(params[:report].merge(:mission_id => current_mission.id))
    end
  
    # prepares and renders the show template, which is used for new and show actions
    def render_show
      # setup data to be used on client side
      build_report_data
      
      render(:show)
    end
end
