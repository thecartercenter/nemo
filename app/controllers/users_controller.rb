class UsersController < ApplicationController
  include BatchProcessable

  # special find method before load_resource
  before_filter :build_user_with_proper_mission, :only => [:new, :create]

  # authorization via CanCan
  load_and_authorize_resource

  def index
    # sort and eager load
    @users = @users.by_name

    # if there is a search with the '.' character in it, we can't eager load due to a bug in Rails
    # this should be fixed in Rails 4
    unless params[:search].present? && params[:search].match(/\./)
      @users = @users.with_assoc
    end

    # do search if applicable
    if params[:search].present?
      begin
        @users = User.do_search(@users, params[:search])
      rescue Search::ParseError
        flash.now[:error] = $!.to_s
        @search_error = true
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
      flash.now[:error] = I18n.t('activerecord.errors.models.user.general')
      prepare_and_render_form
    end
  end

  def update
    permitted_params = user_params

    # don't care about assignment role if updated user is an admin
    if current_user.admin? && params[:id].to_s == current_user.id.to_s &&
      !permitted_params[:assignments_attributes].blank? &&
      !permitted_params[:assignments_attributes][:role].blank?
      permitted_params.delete :assignments_attributes
    end

    # make sure changing assignment role is permitted if attempting
    authorize!(:change_assignments, @user) if permitted_params[:assignments_attributes]

    @user.assign_attributes(permitted_params)
    pref_lang_changed = @user.pref_lang_changed?

    if @user.save

      if @user == current_user
        I18n.locale = @user.pref_lang.to_sym if pref_lang_changed
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
      flash.now[:error] = I18n.t('activerecord.errors.models.user.general')
      prepare_and_render_form
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

  def regenerate_key
    @user = User.find(params[:id])
    @user.regenerate_api_key
    redirect_to(:action => :edit)
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

      if admin_mode?

        # get assignable missons and roles for this user
        @assignments = @user.assignments.as_json(:include => :mission, :methods => :new_record?)
        @assignment_permissions = @user.assignments.map{|a| can?(:update, a)}
        @assignable_missions = Mission.accessible_by(current_ability, :assign_to).sorted_by_name.as_json(:only => [:id, :name])
        @assignable_roles = Ability.assignable_roles(current_user)

      else

        @current_assignment = @user.assignments_by_mission[current_mission] || @user.assignments.build(:mission => current_mission)

      end

      render(:form)
    end

    # builds a user with an appropriate mission assignment if the current_user doesn't have permission to edit a blank user
    def build_user_with_proper_mission
      @user = User.new(user_params)
      if cannot?(:create, @user) && @user.assignments.empty?
        @user.assignments.build(:mission => current_mission)
      end
    end

    def user_params
      return if params[:user].nil?

      params.require(:user).permit(:name, :login, :email, :phone, :admin,
        :phone2, :pref_lang, :notes, :password, :password_confirmation, :reset_password_method,
        assignments_attributes: [:role, :mission_id, :_destroy, :id])
    end
end
