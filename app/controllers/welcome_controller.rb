class WelcomeController < ApplicationController
  # don't need to authorize up here because done manually
  
  # shows a series of blocks with info about the app
  def index
    # authorize the action (merely a formality!)
    authorize! :show, Welcome
    
    if current_mission
      # load objects for the blocks, making heavy use of accessible_by
      # reports
      @reports = Report::Report.accessible_by(current_ability).by_popularity
      
      # published forms
      @pubd_forms = Form.accessible_by(current_ability).published
      @pub_form_count = @pubd_forms.count
      
      # total unpublished forms
      @unpub_form_count = Form.accessible_by(current_ability).count - @pub_form_count
      
      # total users
      @user_count = User.accessible_by(current_ability).count 
      
      # get a relation for accessible responses
      accessible_responses = Response.accessible_by(current_ability)
      
      # total responses by self for this mission
      @self_response_count = accessible_responses.by(current_user).count
      
      # total responses for this mission
      @total_response_count = accessible_responses.count
      
      # responses received recently
      @recent_responses_count = Response.recent_count(accessible_responses)
      
      # unreviewed response count
      @unreviewed_response_count = accessible_responses.unreviewed.count
    end
    
    # we set this because there is no title on the page, just the blocks
    @dont_print_title = true
    
    # render just the blocks if this is an ajax (auto-refresh) request
    render(:partial => "blocks") if ajax_request?
  end
end
