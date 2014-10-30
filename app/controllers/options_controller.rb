class OptionsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  # returns a json-encoded list of options matching search query params[:q]
  def suggest
    # For some reason, Rails is not respecting the include_root_in_json for this action. So need to specify manually.
    render(:root => false, :json => OptionSuggester.new.suggest(current_mission, params[:q]).as_json(:for_option_set_form => true))
  end
end
