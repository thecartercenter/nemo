class Report::ReportsController < ApplicationController
  def index
    @reports = Report::Report.by_viewed_at
  end
  
  def new
    @report = Report::Report.new(:name => "New Report")
    @show_form = true
    build_filter_and_render_form  
  end
  
  def edit
    @report = Report::Report.find(params[:id])
    @show_form = true
    build_filter_and_render_form  
  end
  
  def show
    @report = Report::Report.find(params[:id])
    build_filter_and_render_form  
  end
  
  def destroy
    @report = Report::Report.find(params[:id])
    begin flash[:success] = @report.destroy && "Report deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end    
  
  def create; crupdate; end
  def update; crupdate; end

  private
    def crupdate
      # get/create the report
      @report = params[:action] == "create" ? Report::Report.new : Report::Report.find(params[:id])
      # update the attribs
      @report.attributes = params[:report_report]
      # check validity (setting errors if fail)
      if @report.valid?
        # re-run the report
        @report.run
        # save if requested
        @report.save if params[:save] == "true" && @report.errors.empty?
      end
      # return data in json format (this includes any errors)
      render(:json => @report.to_json)
    end
    
    def build_filter_and_render_form
      @report.build_filter(:class_name => "Response") unless @report.filter
      @dont_print_title = true
      unless @report.new_record?
        @report.record_viewing
        @report.run
      end
      @js << "report_reports_show"
      render(:show)
    end
end
