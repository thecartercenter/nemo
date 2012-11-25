class UsersController < ApplicationController
  def index
    @users = apply_filters(User.includes(:missions))
  end
  def new
    @user = User.new
    render_form
  end
  def edit
    @user = User.find(params[:id])
    @title = "Edit Profile" if @user == current_user
    render_form
  end
  def update
    @user = User.find(params[:id])
    
    # if this was just the current_mission form, update and redirect back to referrer
    if params[:changing_current_mission]
      # update the user's mission
      @user.current_mission_id = params[:user][:current_mission_id]
      @user.save(:validate => false)

      # update the settings using the new mission
      Setting.copy_to_config(@user.current_mission)
      
      # redirect back to the referrer
      redirect_to(request.referrer)
    else
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
        render_form
      end
    end
  end
  def create
    @user = User.new_with_login_and_password(params[:user])
    if @user.save
      @user.reset_password_if_requested
      flash[:success] = "User created successfully."
      handle_printable_instructions
    else
      render_form
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
    
    def render_form
      # create a blank mission assignment with the appropriate user_id for the boilerplate, but don't add it to the collection
      @blank_assignment = Assignment.new(:active => true, :user_id => current_user.id)
      
      # get assignable missons and roles for this user
      @assignable_missions = Permission.assignable_missions(current_user)
      @assignable_roles = Permission.assignable_roles(current_user)
      
      render(:form)
    end
end
