class OptionsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  # Returns a json-encoded list of options matching search query params[:q]
  def suggest
    suggestions = OptionSuggester.new.suggest(current_mission, params[:q])
    render json: suggestions.as_json(for_option_set_form: true)
  end
end
