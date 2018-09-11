# methods required to embed a report display in a page
module ReportEmbeddable
  # sets up the @report_data structure which will be converted to json
  def build_report_data(options = {})
    @report_data = {report: @report.as_json(methods: :errors)}

    # merge in options from method call
    @report_data.merge!(options)

    # add stuff for report editing, if appropriate
    unless options[:read_only]
      @report_data[:options] = {
        attribs: Report::AttribField.all,
        forms: Form.for_mission(current_mission).by_name.as_json(only: [:id, :name]),
        calculation_types: Report::Calculation::TYPES,
        questions: Question.for_mission(current_mission).reportable.includes(:forms, :option_set).by_code.as_json(
          only: [:id, :code, :qtype_name],
          methods: [:form_ids, :geographic?]
        ),
        option_sets: OptionSet.for_mission(current_mission).by_name.as_json(only: [:id, :name]),
        percent_types: Report::Report::PERCENT_TYPES,

        # the names of qtypes that can be used in headers
        headerable_qtype_names: QuestionType.all.select(&:headerable?).map(&:name)
      }
    end

    Rails.logger.debug("****** REPORT TYPE ******")
    Rails.logger.debug(@report.type)
    @report_data[:report][:generated_at] = I18n.l(Time.zone.now)
    @report_data[:report][:user_can_edit] = can?(:update, @report)
    @form_type = @report.model_name.singular_route_key.remove(/^report_/)
    if @report.type.present? && @report.type == "Report::StandardFormReport"
      @report_data[:report][:html] =
        render_to_string(partial: "reports/#{@form_type}/form_summary_display")
    end
  end

  # Looks for a cached, populated report object matching @report.
  # If one is found, stores it in @report. If not found,
  # calls run on the existing @report
  #
  # returns true if no errors, false otherwise
  def run_or_fetch_and_handle_errors(options = {})
    begin
      @report = Rails.cache.fetch(cache_key_with_responses) do
        @report.run(current_ability, options)
        @report
      end

      return true
    rescue Report::ReportError, Search::ParseError
      flash.now[:error] = $!.to_s
      return false
    end
  end

  def cache_key_with_responses
    [
      I18n.locale.to_s,

      # Need to include this because enumerators see only own data
      current_user.role(current_mission) == "enumerator" ? "enumerator-#{current_user.id}" : nil,

      Response.per_mission_cache_key(current_mission),
      @report.cache_key
    ].compact.join('-')
  end
end
