class UserGroupsController < ApplicationController

  load_and_authorize_resource

  def index
    render(partial: "index_table") if request.xhr?
  end
end
