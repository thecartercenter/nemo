# methods required to embed a report display in a page
module ReportEmbeddable
  # sets up the @report_data structure which will be converted to json
  def build_report_data(options = {})
    @report_data = {:report => @report.as_json(:methods => :errors)}
    
    # add stuff for report editing, or read only flag, if appropriate
    if options[:read_only]
      @report_data[:read_only] = true
    else
      @report_data[:options] = {
        :attribs => Report::AttribField.all,
        :forms => Form.for_mission(current_mission).all,
        :calculation_types => Report::Calculation::TYPES,
        :questions => Question.for_mission(current_mission).with_forms.all.as_json(:methods => :form_ids),
        :option_sets => OptionSet.for_mission(current_mission).all,
        :percent_types => Report::Report::PERCENT_TYPES
      }
    end
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
end