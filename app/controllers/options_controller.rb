class OptionsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource
  
  # returns a json-encoded list of options matching search query params[:q]
  def suggest
    render(:json => Option.suggestions(current_mission, params[:q]).to_json)
  end
end
