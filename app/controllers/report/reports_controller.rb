class Report::ReportsController < ApplicationController
  def index
    @reports = apply_filters(Report::Report.by_popularity).all.collect{|r| r.becomes(Report::Report)}
  end
  
  def new
    @report = Report::Report.new_with_default_name(current_mission)
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
  
  # only exec'd through json
  def create
    # attempt create the report
    Rails.logger.debug("******* #{current_mission}")
    @report = Report::Report.for_mission(current_mission).create(params[:report].merge(:mission_id => current_mission.id))

    # if report is valid, save it set flag (no need to run it b/c it will be redirected)
    @report.just_created = true if @report.errors.empty?
    
    # return data in json format
    render(:json => build_hash.to_json)
  end

  # only exec'd through json
  def update
    # get/create the report
    @report = Report::Report.find(params[:id])
    # update the attribs
    @report.attributes = params[:report]
    
    # if report is not valid, can't run it
    if @report.valid?
      # re-run the report, handling errors
      run_and_handle_errors
      # save
      @report.save
    end
    
    # return data in json format
    render(:json => build_hash.to_json)
  end

  private
    def init_obj_and_render_form
      #@report.build_filter(:class_name => "Response") unless @report.filter
      #@report.fields.build(:full_id => nil) if @report.fields.empty?
      #@question_types = QuestionType.all
      #@aggregations = Report::Aggregation.all
      #@groupable_response_attributes = Report::ResponseAttribute.groupable
      #@groupable_questions = restrict(Question).select_types
      #@dont_print_title = true
      
      # if not a new record, run it and record viewing
      unless @report.new_record?
        @report.record_viewing
        run_and_handle_errors
      end
      
      # set json instance variable to be used in template
      
      @report_json = build_hash.merge({
        :can_edit => authorized?(:action => "report_reports#update"),
        :options => {
          :calculation_types => Report::Calculation.types,
          :questions => Question.for_mission(current_mission).all,
          :option_sets => OptionSet.for_mission(current_mission).all,
          :percent_types => Report::Report::PERCENT_TYPES
        }
      }).to_json
      
      render(:show)
    end
    
    def run_and_handle_errors
      begin
        @report.run
      rescue Report::ReportError, Search::ParseError
        @report.errors.add(:base, $!.to_s)
        return false
      rescue
        @unhandled_error = $!.to_s
        Rails.logger.debug("#{$!.message}\n#{$!.backtrace.join("\n")}")
        return false
      end
      return true
    end
    
    def build_hash
      {
        :report => @report,
        :unhandled_error => @unhandled_error
      }
    end
end
