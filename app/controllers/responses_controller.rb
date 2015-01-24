class ResponsesController < ApplicationController
  include CsvRenderable

  # need to load with associations for show and edit
  before_filter :load_with_associations, :only => [:show, :edit]

  # authorization via CanCan
  load_and_authorize_resource

  before_filter :mark_response_as_checked_out, :only => [:edit]

  def index
    # Disable cache, including back button
    response.headers['Cache-Control'] = 'no-cache, max-age=0, must-revalidate, no-store'

    # handle different formats
    respond_to do |format|
      # html is the normal index page
      format.html do
        # apply search and pagination
        params[:page] ||= 1

        # paginate
        @responses = @responses.paginate(:page => params[:page], :per_page => 20)

        # include answers so we can show key questions
        @responses = @responses.includes(:answers)

        # do search, including excerpts, if applicable
        if params[:search].present?
          begin
            @responses = Response.do_search(@responses, params[:search], {:mission => current_mission}, :include_excerpts => true)
          rescue Search::ParseError
            flash.now[:error] = $!.to_s
            @search_error = true
          rescue ThinkingSphinx::SphinxError
            # format sphinx message a little more nicely
            sphinx_msg = $!.to_s.gsub(/index .+?:\s+/, '')
            flash.now[:error] = sphinx_msg
            @search_error = true
          end
        end

        # render just the table if this is an ajax request
        render(:partial => "table_only", :locals => {:responses => @responses}) if request.xhr?
      end

      # csv output is for exporting responses
      format.csv do
        # do search, excluding excerpts
        if params[:search].present?
          begin
            @responses = Response.do_search(@responses, params[:search], {:mission => current_mission}, :include_excerpts => false)
          rescue Search::ParseError
            flash.now[:error] = $!.to_s
            return
          end
        end

        # get the response, for export, but not paginated
        @responses = Response.for_export(@responses)

        # render the csv
        render_csv("elmo-#{current_mission.compact_name}-responses-#{Time.zone.now.to_s(:filename_datetime)}")
      end
    end
  end

  def show
    # if there is a search param, we try to load the response via the do_search mechanism so that we get highlighted excerpts
    if params[:search]
      # we pass a relation matching only one respoonse, so there should be at most one match
      matches = Response.do_search(Response.where(:id => @response.id), params[:search], {:mission => current_mission},
        :include_excerpts => true, :dont_truncate_excerpts => true)

      # if we get a match, then we use that object instead, since it contains excerpts
      @response = matches.first if matches.first
    end
    prepare_and_render_form
  end

  def new
    # get the form specified in the params and error if it's not there
    begin
      @response.form = Form.find(params[:form_id])
    rescue ActiveRecord::RecordNotFound
      return redirect_to(index_url_with_page_num)
    end

    # render the form template
    prepare_and_render_form
  end

  def edit
    flash.now[:notice] = "#{t("response.checked_out")} #{@response.checked_out_by_name}" if @response.checked_out_by_others?(current_user)
    prepare_and_render_form
  end

  def create

    # if this is a non-web submission
    if request.format == Mime::XML

      # if the method is HEAD or GET just render the 'no content' status since that's what odk wants!
      if %w(HEAD GET).include?(request.method)
        render(:nothing => true, :status => 204)

      # otherwise, we should process the submission
      else
        begin
          @response.user_id = current_user.id

          # If it looks like a J2ME submission, process accordingly
          if params[:data] && params[:data][:'xmlns:jrm'] == 'http://dev.commcarehq.org/jr/xforms'
            @response.populate_from_j2me(params[:data])

          # Otherwise treat it like an ODK submission
          else
            upfile = params[:xml_submission_file]

            unless upfile
              render_xml_submission_failure('No XML file attached.', 422)
              return false
            end

            xml = upfile.read
            Rails.logger.info("----------\nXML submission:\n#{xml}\n----------")
            @response.populate_from_odk(xml)
          end

          # ensure response's user can submit to the form
          authorize!(:submit_to, @response.form)

          # save without validating, as we have no way to present validation errors to user,
          # and submitting apps already do validation
          @response.save(:validate => false)

          render(:nothing => true, :status => 201)

        rescue CanCan::AccessDenied
          render_xml_submission_failure($!, 403)

        rescue ActiveRecord::RecordNotFound
          render_xml_submission_failure($!, 404)

        rescue FormVersionError
          # 426 - upgrade needed
          # We use this because ODK can't display custom failure messages so this provides a little more info.
          render_xml_submission_failure($!, 426)

        rescue SubmissionError
          render_xml_submission_failure($!, 422)
        end
      end

    # for HTML format just use the method below
    else
      web_create_or_update
    end
  end

  def update
    @response.assign_attributes(params[:response])
    web_create_or_update
  end

  def destroy
    destroy_and_handle_errors(@response)
    redirect_to(index_url_with_page_num)
  end

  private
    # loads the response with its associations
    def load_with_associations
      @response = Response.with_associations.find(params[:id])
    end

    # when editing a response, set timestamp to show it is being worked on
    def mark_response_as_checked_out
      @response.check_out!(current_user)
    end

    # handles creating/updating for the web form
    def web_create_or_update
      # set source/modifier to web
      @response.source = "web" if params[:action] == "create"
      @response.modifier = "web"

      # check for "update and mark as reviewed"
      @response.reviewed = true if params[:commit_and_mark_reviewed]

      if params[:action] == "update"
        @response.check_in
      end

      # try to save
      begin
        @response.save!
        set_success_and_redirect(@response)
      rescue ActiveRecord::RecordInvalid
        flash.now[:error] = I18n.t('activerecord.errors.models.response.general')
        prepare_and_render_form
      end
    end

    # prepares objects for and renders the form template
    def prepare_and_render_form
      # get the users to which this response can be assigned
      # which is the users in this mission plus admins
      # (we need to include admins because they can submit forms to any mission)
      @possible_submitters = User.assigned_to_or_admin(current_mission).by_name

      # render the form
      render(:form)
    end

    def render_xml_submission_failure(exception, code)
      Rails.logger.info("XML submission failed: '#{exception.to_s}'")
      render(:nothing => true, :status => code)
    end
end
