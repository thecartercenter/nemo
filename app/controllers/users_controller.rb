class UsersController < ApplicationController
  before_filter :require_user
  def index
    @users = User.sorted(params[:page])
    @total_count = User.count
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
      flash[:success] = "User updated successfully."
      redirect_to(:action => :index)
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
    @user.destroy and flash[:success] = "User deleted successfully" rescue flash[:error] = $!.to_s
    redirect_to(:action => :index)
  end
end
