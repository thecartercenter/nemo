class OptionsController < ApplicationController
  def index
    # find or create a subindex object
    @subindex = Subindex.find_and_update(session, current_user, "Option", params[:page])
    # get the questions
    @options = Option.sorted(@subindex.params)
  end
end
