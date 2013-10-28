class OptionsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource
  
  # returns a json-encoded list of options matching search query params[:q]
  def suggest
    render(:json => Option.suggestions(current_mission, params[:q]).as_json(:for_option_set_form => true))
  end
end
