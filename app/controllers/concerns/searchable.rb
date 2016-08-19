# Methods pertaining to searching for objects in a controller action.
module Searchable
  extend ActiveSupport::Concern

  # If params[:search] is present, runs a search of `klass`,
  # passing `rel` as the relation to which to apply the search.
  # Returns the new relation if search succeeds,
  # otherwise sets flash, @search_error = true, and returns `rel` unchanged.
  def apply_search_if_given(klass, rel)
    if params[:search].present?
      apply_search(klass, rel)
    else
      rel
    end
  end

  def apply_search(klass, rel)
    begin
      return klass.do_search(rel, params[:search])
    rescue Search::ParseError
      flash.now[:error] = $!.to_s
      @search_error = true
      return rel
    end
  end
end
