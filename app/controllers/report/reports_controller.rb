class Report::ReportsController < ApplicationController
  def index
    @reports = Report::Report.by_viewed_at
  end
  
  def new
    @report = Report::Report.new
    build_filter_and_render_form  
  end
  
  def edit
    @report = Report::Report.find(params[:id])
    build_filter_and_render_form
  end
  
  def show
    @report = Report::Report.find(params[:id])
    @report.build_filter(:class_name => "Response") unless @report.filter
    @title = @report.name
    @dont_print_title = true
    @report.record_viewing
    @report.run
    @js << "report_reports_show"
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
      # if ajax request
      if ajax_request?
        begin 
          @report = Report::Report.find(params[:id])
          @report.attributes = params[:report_report]
          # save if requested
          if params[:save] == "true"
            @report.save! 
            Rails.logger.debug("saving!")
          end
          # rerun if requested
          if params[:rerun] == "true"
            @report.run
            # return data in json format
            render(:json => @report.to_json)
          else
            render(:nothing => true)
          end
        rescue
          
        end
      else
        action = params[:action]
        @report = action == "create" ? Report::Report.new : Report::Report.find(params[:id])
        begin
          @report.update_attributes!(params[:report_report])
          redirect_to(:action => :show, :id => @report.id)
        rescue ActiveRecord::RecordInvalid
          build_filter_and_render_form
        end
      end
    end
    
    def build_filter_and_render_form
      @report.build_filter(:class_name => "Response") unless @report.filter
      render(:form)
    end
end
