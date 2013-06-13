class UsersController < ApplicationController
  # authorization via CanCan
  load_and_authorize_resource
  
  def index
    # apply pagination and search, and include mission association
    @users = apply_filters(@users.includes(:missions))
  end
  
  def new
    # set the default pref_lang based on the mission settings
    @user.pref_lang = configatron.languages.first || I18n.default_locale
    prepare_and_render_form
  end
  
  def show
    prepare_and_render_form
  end
  
  def edit
    prepare_and_render_form
  end
  
  def create
    if @user.save
      @user.reset_password_if_requested

      set_success(@user)
      
      # render printable instructions if requested
      handle_printable_instructions
    
    # if create failed, render the form again
    else
      prepare_and_render_form
    end
  end

  def update
    # if this was just the current_mission form (in the banner), update and redirect back to referrer
    if params[:changing_current_mission]
      # update the user's mission
      @user.change_mission!(Mission.find(params[:user][:current_mission_id]))

      # update the settings using the new mission
      Setting.copy_to_config(@user.current_mission)
      
      # redirect back to the referrer, and set a flag
      flash[:mission_changed] = true
      redirect_to(request.referrer)
    
    # otherwise this is a normal update
    else
      # try to save
      if @user.update_attributes(params[:user])

        # redirect and message depend on if this was user editing self or not
        if @user == current_user
          flash[:success] = t("users.profile_updated")
          redirect_to(:action => :edit)
        else
          set_success(@user)

          # if the user's password was reset, do it, and show instructions if requested
          @user.reset_password_if_requested
          
          handle_printable_instructions
        end
      
      # if save failed, render the form again
      else
        prepare_and_render_form
      end
    end
  end
  
  def destroy
    destroy_and_handle_errors(@user)
    redirect_to(:action => :index)
  end
  
  # shows printable login instructions for the user
  def login_instructions
  end
  
  # exports the selected users to VCF format
  def export
    respond_to do |format|
      format.vcf do
        @users = params[:selected] ? load_selected_objects(User) : []
        render(:text => @users.collect{|u| u.to_vcf}.join("\n"))
      end
    end
  end
  
  private
    
    # if we need to print instructions, redirects to the instructions action. otherwise redirects to index.
    def handle_printable_instructions
      if @user.reset_password_method == "print"
        # save the password in the flash since we won't be able to get it once it's crypted
        flash[:password] = @user.password
        redirect_to(:action => :login_instructions, :id => @user.id)
      else
        redirect_to(:action => :index)
      end
    end
    
    # prepares objects and renders the form template
    def prepare_and_render_form
      # create a blank mission assignment with the appropriate user_id for the boilerplate, but don't add it to the collection
      @blank_assignment = Assignment.new(:active => true, :user_id => current_user.id)
      
      # get assignable missons and roles for this user
      @assignable_missions = Mission.accessible_by(current_ability)
      @assignable_roles = Ability.assignable_roles(current_user)
      
      render(:form)
    end
end
