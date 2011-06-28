class PlaceLookupsController < ApplicationController
  before_filter(:authorize)
  def new
    set_title_and_js
    @place_lookup = PlaceLookup.new
  end
  def edit
    new
  end
  def suggest
    # Get results from local places and google geolocator.
    place_lookup = PlaceLookup.suggest(params[:query])
    render(:partial => "results", :locals => {:place_lookup => place_lookup, :ajax => true})
  end
  def create
    update
  end
  def update
    @place_lookup = PlaceLookup.find_and_update(params[:place_lookup])
    if @place_lookup.spawn
      flash[:success] = "Place added successfully."
      redirect_to(places_path)
    else
      set_title_and_js
      render(:action => :new)
    end
  end
  private
    def set_title_and_js
      @title = "Add Place: Lookup"
      @js << 'place_lookups'
    end
end
