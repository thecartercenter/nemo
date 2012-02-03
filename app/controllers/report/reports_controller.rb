class Report::ReportsController < ApplicationController
  def index
    @reports = Report::Report.all
  end
  
  def new
    @report = Report::Report.new
    @report.build_filter(:class_name => "Response")
    render(:form)
  end
  
  def edit
    @report = Report::Report.find(params[:id])
    render(:form)
  end
  
  def show
    @report = Report::Report.find(params[:id])
    @report.run
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
