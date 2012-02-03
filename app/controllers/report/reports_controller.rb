class Report::ReportsController < ApplicationController
  def index
    @reports = Report::Report.by_viewed_at
  end
  
  def new
    @report = Report::Report.new
    @report.build_filter(:class_name => "Response")
    render(:form)
  end
  
  def edit
    @report = Report::Report.find(params[:id])
    @report.build_filter(:class_name => "Response") unless @report.filter
    render(:form)
  end
  
  def show
    @report = Report::Report.find(params[:id])
    @title = @report.name
    @report.record_viewing
    @report.run
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
      action = params[:action]
      @report = action == "create" ? Report::Report.new : Report::Report.find(params[:id])
      begin
        @report.update_attributes!(params[:report_report])
        redirect_to(:action => :show, :id => @report.id)
      rescue ActiveRecord::RecordInvalid
        render(:action => :form)
      end
    end
end
