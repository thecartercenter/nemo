class SearchesController < ApplicationController
  
  def create
    # find/create the search object from the given params
    search = Search.find_or_create(params[:search])
    # save it in the appropriate subindex object
    subindex = Subindex.find_or_create(session, search.class_name)
    subindex.search = search
    # redirect to the appropriate index page
    return_to_index(search)
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
