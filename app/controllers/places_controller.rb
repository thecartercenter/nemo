class PlacesController < ApplicationController
  before_filter :require_user
  def index
  end
  def new
    set_title_and_js
    @place = Place.new
    @place_lookup = PlaceLookup.new
  end
  def create
    @place = Place.new(params[:place])
    @place_lookup = PlaceLookup.find_and_update(params[:place_lookup])
    @place.container = @place_lookup.choice
    if @place.save
      flash[:success] = "Place added successfully."
      redirect_to(:action => :index)
    else
      set_title_and_js
      render(:action => :new)
    end
  end
  private
    def set_title_and_js
      @title = "Add Place: Manual"
      @js << 'place_lookups'
    end
end
