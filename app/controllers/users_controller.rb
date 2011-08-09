class UsersController < ApplicationController
  
  def index
    # find or create a subindex object
    @subindex = Subindex.find_and_update(session, current_user, "User", params[:page])
    # get the users
    begin
      @users = User.sorted(@subindex.params)
    rescue SearchError
      flash[:error] = $!.to_s
      @users = Place.sorted(:page => 1)
    end
  end
  def new
    @user = User.default
  end
  def edit
    @user = User.find(params[:id])
    @title = "Edit Profile" if @user == current_user
  end
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      if @user == current_user
        flash[:success] = "Profile updated successfully."
        redirect_to(:action => :edit)
      else
        flash[:success] = "User updated successfully."
        redirect_to(:action => :index)
      end
    else
      render(:action => :edit)
    end
  end
  def create
    @user = User.new_with_login_and_password(params[:user])
    if @user.save
      @user.deliver_intro!
      flash[:success] = "User created successfully. An email containing login instructions " +
        "has been sent to the address you provided."
      redirect_to(:action => :index)
    else
      render(:action => :new)
    end
  end
  def destroy
    @user = User.find(params[:id])
    begin flash[:success] = @user.destroy && "User deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
end
