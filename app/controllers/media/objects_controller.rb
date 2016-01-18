class Media::ObjectsController < ApplicationController
  before_action :set_media_object, only: [:show, :edit, :update, :destroy]
  skip_authorization_check

  # GET /media/objects/1
  # GET /media/objects/1.json
  def show
    style = params[:style]
    send_file @media_object.item.path(style), type: @media_object.item_content_type, disposition: 'inline'
  end

  # GET /media/objects/new
  def new
    @media_object = Media::Object.new
  end

  # GET /media/objects/1/edit
  def edit
  end

  # POST /media/objects
  # POST /media/objects.json
  def create
    @media_object = Media::Object.new(media_object_params)

    respond_to do |format|
      if @media_object.save
        format.html { redirect_to @media_object, notice: 'Object was successfully created.' }
        format.json { render json: @media_object, status: :created }
      else
        format.html { render action: 'new' }
        format.json { render json: @media_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /media/objects/1
  # PATCH/PUT /media/objects/1.json
  def update
    respond_to do |format|
      if @media_object.update(media_object_params)
        format.html { redirect_to @media_object, notice: 'Object was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @media_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /media/objects/1
  # DELETE /media/objects/1.json
  def destroy
    @media_object.destroy
    respond_to do |format|
      format.html { redirect_to media_objects_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_media_object
      @media_object = Media::Object.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def media_object_params
      params.require(:media_object).permit(:answer_id, :annotation)
    end
end
