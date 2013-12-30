class UsersController < ApplicationController
  # special find method before load_resource
  before_filter :build_user_with_proper_mission, :only => [:new, :create]

  # authorization via CanCan
  load_and_authorize_resource

  def index
    # sort and eager load
    @users = @users.by_name.with_assoc

    # do search if applicable
    if params[:search].present?
      begin
        @users = User.do_search(@users, params[:search])
      rescue Search::ParseError
        @error_msg = "#{t('search.search_error')}: #{$!}"
      end
    end
  end

  def new
    # set the default pref_lang based on the mission settings
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
      # update the user's mission. a blank mission_id means set mission to nil
      new_mission = params[:user][:current_mission_id].blank? ? nil : Mission.find(params[:user][:current_mission_id])
      @user.change_mission!(new_mission)

      # redirect back to the referrer (stripping query string), and set a flag
      flash[:mission_changed] = true
      redirect_to(referrer_without_query_string)

    # otherwise this is a normal update
    else
      # make sure changing assignment role is permitted if attempting
      authorize!(:change_assignments, @user) if params[:user]['assignments_attributes']

      # try to save
      if @user.update_attributes(params[:user])

        # redirect and message depend on if this was user editing self or not
        if @user == current_user
          flash[:success] = t("user.profile_updated")
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
    redirect_to(index_url_with_page_num)
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

  # sets the current user's current mission to the last one used, and redirects to home page for that mission
  def exit_admin_mode
    if m = Mission.where(:id => session[:last_mission_id]).first
      current_user.change_mission!(m)
    end
    redirect_to(root_url(:admin_mode => nil))
  end

  private

    # if we need to print instructions, redirects to the instructions action. otherwise redirects to index.
    def handle_printable_instructions
      if @user.reset_password_method == "print"
        # save the password in the flash since we won't be able to get it once it's crypted
        flash[:password] = @user.password
        redirect_to(:action => :login_instructions, :id => @user.id)
      else
        redirect_to(index_url_with_page_num)
      end
    end

    # prepares objects and renders the form template
    def prepare_and_render_form
      # create a blank mission assignment with the appropriate user_id for the boilerplate, but don't add it to the collection
      @blank_assignment = Assignment.new(:active => true, :user_id => current_user.id)

      # get assignable missons and roles for this user
      @assignable_missions = Mission.accessible_by(current_ability, :assign_to).sorted_by_name
      @assignable_roles = Ability.assignable_roles(current_user)

      render(:form)
    end

    # builds a user with an appropriate mission assignment if the current_user doesn't have permission to edit a blank user
    def build_user_with_proper_mission
      @user = User.new(params[:user])
      if cannot?(:create, @user) && @user.assignments.empty?
        @user.assignments.build(:mission => current_mission, :active => true)
      end
    end
end
