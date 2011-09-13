class PlaceCreatorsController < ApplicationController
  def new
    @place_creator = PlaceCreator.new
    set_title_and_js
  end
  def create
    # at this point all we have to do is just mark the chosen place non-temporary
    @place = Place.find(params[:place_creator][:place_id])
    @place.temporary = false
    begin 
      @place.save!
      flash[:success] = "Place added successfully."
      redirect_to(:action => :new)
    rescue
      flash[:error] = "Problem adding place (#{$!.to_s})."
      set_title_and_js
      render(:action => :new)
    end
  end
  private
    def set_title_and_js
      @title = "Add Place: Using Google"
      @js << "places"
    end
end
