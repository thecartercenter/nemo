class Report::ReportsController < ApplicationController
  def index
    @reports = Report::Report.by_popularity
  end
  
  def new
    @report = Report::Report.new_with_default_name
    @show_form = true
    init_obj_and_render_form
  end
  
  def edit
    flash[:saved] = true and return redirect_to(:action => :edit) if params[:show_success]
    @report = Report::Report.find(params[:id])
    @show_form = true
    init_obj_and_render_form
  end
  
  def show
    @report = Report::Report.find(params[:id])
    init_obj_and_render_form
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
    
    def init_obj_and_render_form
      @report.build_filter(:class_name => "Response") unless @report.filter
      @report.fields.build(:full_id => nil) if @report.fields.empty?
      @dont_print_title = true
      unless @report.new_record?
        @report.record_viewing
        begin
          @report.run
        rescue Report::ReportError
          @report.errors.add(:base, $!.to_s)
        end
      end
      @js << "report_reports_show"
      render(:show)
    end
end
