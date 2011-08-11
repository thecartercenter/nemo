class SearchesController < ApplicationController
  
  def create
    # find/create the search object from the given params
    search = Search.find_or_create(params[:search])
    # save it in the appropriate subindex object
    subindex = Subindex.find_or_create(session, current_user, search.class_name)
    subindex.search = search
    # redirect to the appropriate index page
    return_to_index(search)
  end
  # this is a GET method that just copies parameters and calls create
  def start
    params[:search] = {}
    [:query, :class_name].each{|k| params[:search][k] = params.delete(k)}
    create
  end
  def update
    create
  end
  private
    # redirects to the appropriate index page for the given search
    def return_to_index(search)
      redirect_to(:controller => search.class_name.pluralize.underscore, :action => :index)
    end
end
