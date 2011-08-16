class PlacesController < ApplicationController
  
  def index
    @places = load_objects_with_subindex(Place)
  end
  def map
    @title = "Place Map"
    @js << "map"
    @places = Place.all(:conditions => "latitude is not null and longitude is not null")
    @bounds = Place.bound(@places)
  end
  def new
    set_add_title
    set_js
    @place = Place.new
    @place_lookup = PlaceLookup.new
  end
  def edit
    # lookup the place
    @place = Place.find(params[:id])
    # get a fresh place_lookup object
    @place_lookup = PlaceLookup.new
    # setup the required js
    set_js
  end
  def update
    # lookup the place
    @place = Place.find(params[:id])
    # update the place lookup
    @place_lookup = PlaceLookup.find_and_update(params[:place_lookup])
    # update the container if place_lookup has been used
    (choice = @place_lookup.choice) ? @place.container = choice : nil
    # try to update
    if @place.update_attributes(params[:place])
      flash[:success] = "Place updated successfully."
      redirect_to(:action => :index)
    else
      set_js
      render(:action => :edit)
    end
  end
  def create
    @place = Place.new(params[:place])
    @place_lookup = PlaceLookup.find_and_update(params[:place_lookup])
    @place.container = @place_lookup.choice
    if @place.save
      flash[:success] = "Place added successfully."
      redirect_to(:action => :index)
    else
      set_add_title
      set_js
      render(:action => :new)
    end
  end
  def destroy
    @place = Place.find(params[:id])
    begin
      @place.destroy
      flash[:success] = "Place deleted successfully" 
    rescue 
      flash[:error] = $!.to_s
    end
    redirect_to(:action => :index)
  end
  private
    def set_add_title
      @title = "Add Place: Manual"
    end
    def set_js
      @js << 'place_lookups'
    end
end
