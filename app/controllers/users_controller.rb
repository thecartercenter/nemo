class UsersController < ApplicationController
  def index
    @users = load_objects_with_subindex(User)
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
        @user.reset_password_if_requested
        handle_printable_instructions
      end
    else
      render(:action => :edit)
    end
  end
  def create
    @user = User.new_with_login_and_password(params[:user])
    if @user.save
      @user.reset_password_if_requested
      flash[:success] = "User created successfully."
      handle_printable_instructions
    else
      render(:action => :new)
    end
  end
  def destroy
    @user = User.find(params[:id])
    begin flash[:success] = @user.destroy && "User deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
  def login_instructions
    @user = User.find(params[:id])
    @title = ""
  end
  def export
    respond_to do |format|
      format.vcf do
        @users = params[:selected] ? load_selected_objects(User) : []
        render(:text => @users.collect{|u| u.to_vcf}.join("\n"))
      end
    end
  end
  
  private
    def handle_printable_instructions
      # if we need to print instructions, redirect there. otherwise redirect to index
      if @user.reset_password_method == "print"
        # save the password in the flash since we won't be able to get it in the next request
        flash[:password] = @user.password
        redirect_to(:action => :login_instructions, :id => @user.id)
      else
        redirect_to(:action => :index)
      end
    end
end
