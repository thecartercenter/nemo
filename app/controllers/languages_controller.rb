class LanguagesController < ApplicationController
  before_filter :require_user
  def index
    @languages = Language.sorted(:paginate => true, :page => params[:page])
  end
  def new
    @language = Language.default
  end
  def edit
    @language = Language.find(params[:id])
  end
  def create
    @language = Language.new(params[:language])
    if @language.save
      flash[:success] = "Language created successfully."
      redirect_to(:action => :index)
    else
      render(:action => :new)
    end
  end
  def update
    @language = Language.find(params[:id])
    if @language.update_attributes(params[:language])
      flash[:success] = "Language updated successfully."
      redirect_to(:action => :index)
    else
      render(:action => :edit)
    end
  end
  def destroy
    @language = Language.find(params[:id])
    begin flash[:success] = @language.destroy && "Language deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
end
