# frozen_string_literal: true

class UsersController < ApplicationController
  PER_PAGE = 50

  include BatchProcessable
  include Searchable
  include PasswordResettable

  # These filters need to be before load_and_authorize_resource because they preemptively setup @user
  # before load_and_authorize_resource because if left to its own devices, load_and_authorize_resource
  # would mess things up with user_groups and mission permissions!
  before_action :build_user_with_proper_mission, only: :new
  before_action :load_user, only: %i[update create]

  load_and_authorize_resource

  before_action :require_recent_login, except: %i[export index login_instructions]

  helper_method :reset_password_options

  decorates_assigned :users

  def index
    # sort and eager load
    @users = @users.with_assoc.by_name
    @groups = UserGroup.accessible_by(current_ability).order(:name)
    @search_params = params[:search]
    @users = apply_search(@users)

    # Apply pagination
    @users = @users.paginate(page: params[:page], per_page: PER_PAGE)
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
      reset_password(@user, mission: current_mission, notify_method: @user.reset_password_method)
      set_success(@user)

      # render printable instructions if requested
      handle_printable_instructions || redirect_to(index_url_with_context)

    # if create failed, render the form again
    else
      flash.now[:error] = I18n.t("activerecord.errors.models.user.general")
      prepare_and_render_form
    end
  end

  def update
    # In cases where the user can't change these things, the params shouldn't even appear at all
    # since the fields shouldn't be rendered. So it's enough to just check if they're there.
    authorize!(:change_assignments, @user) if params[:user].key?(:assignments_attributes)
    authorize!(:activate, @user) if params[:user].key?(:active)

    pref_lang_changed = @user.pref_lang_changed?

    if @user.save
      # if the user's password was reset, do it, and show instructions if requested
      reset_password(@user, mission: current_mission, notify_method: @user.reset_password_method)

      if @user == current_user
        I18n.locale = @user.pref_lang.to_sym if pref_lang_changed
        flash[:success] = t("user.profile_updated")
      else
        set_success(@user)
      end

      handle_printable_instructions || redirect_to(action: :edit)

    # if save failed, render the form again
    else
      flash.now[:error] = I18n.t("activerecord.errors.models.user.general")
      prepare_and_render_form
    end
  end

  def destroy
    destroy_and_handle_errors(@user)
    redirect_to(index_url_with_context)
  end

  def bulk_destroy
    @users = restrict_by_search_and_ability_and_selection(@users)
    result = UserDestroyer.new(scope: @users, user: current_user, ability: current_ability).destroy!
    destroyed, deactivated, skipped = result.values_at(:destroyed, :deactivated, :skipped)
    success = []
    success << t("user.bulk_destroy_deleted", count: destroyed) if destroyed.positive?
    success << t("user.bulk_destroy_deactivated", count: deactivated) if deactivated.positive?
    success << t("user.bulk_destroy_skipped", count: skipped) if skipped.positive?
    flash[:success] = success.join(" ") unless success.empty?
    flash[:alert] = t("user.bulk_destroy_skipped_current") if skipped == 1
    redirect_to(index_url_with_context)
  end

  # shows printable login instructions for the user
  def login_instructions
    @password = flash[:password] || Rails.env.test? && ENV["STUB_PASSWORD"]
    @site_url = admin_mode? ? basic_root_url : mission_root_url
    encoded_config = ODK::UserConfigEncoder.new(@user.login, flash[:password], @site_url).encode_config
    @config_qr = RQRCode::QRCode.new(encoded_config)
  end

  # exports the selected users to VCF format
  def export
    respond_to do |format|
      format.vcf do
        @users = restrict_scope_to_selected_objects(User.accessible_by(current_ability))
        render(plain: @users.collect(&:to_vcf).join("\n"))
      end
    end
  end

  def regenerate_api_key
    @user.regenerate_api_key
    @user.save(validate: false)
    render(json: {value: @user.api_key})
  end

  def regenerate_sms_auth_code
    @user.regenerate_sms_auth_code
    @user.save(validate: false)
    render(json: {value: @user.sms_auth_code})
  end

  private

  def reset_password_options(user)
    options = []
    options << :dont unless user.new_record?
    options << :email unless offline_mode?
    options << :print if admin_mode? && offline_mode? || mission_mode?
    options << (mission_mode? ? :enter_and_show : :enter)
    options
  end

  # if we need to print instructions, redirects to the instructions action. otherwise redirects to index.
  def handle_printable_instructions
    if %w[print enter_and_show].include?(@user.reset_password_method)
      # save the password in the flash since we won't be able to get it once it's crypted
      flash[:password] = @user.password
      redirect_to(action: :login_instructions, id: @user.id)
      true
    else
      false
    end
  end

  # prepares objects and renders the form template
  def prepare_and_render_form
    if admin_mode?
      @assignment_data = {missions: accessible_missions.map { |m| MissionSerializer.render_as_hash(m) },
                          assignments: @user.assignments.map { |a| AssignmentSerializer.render_as_hash(a) },
                          roles: Ability.assignable_roles(current_user)}
    else
      @current_assignment = @user.assignments_by_mission[current_mission] ||
        @user.assignments.build(mission: current_mission)
    end
    render(:form)
  end

  def accessible_missions
    Mission.accessible_by(current_ability, :assign_to).sorted_by_name
  end

  # Builds a user with an appropriate mission assignment if the current_user
  # doesn't have permission to edit a user with no assignments.
  # If we don't do this before load_and_authorize_resource runs, we will get a 403.
  def build_user_with_proper_mission
    @user = User.new
    @user.assignments.build(mission: current_mission) if cannot?(:create, @user)
  end

  # Finds or builds a User object and populates with the provided params.
  # We do this here instead of allowing load_and_authorize_resource to do it because
  # the latter would mess up the user_groups stuff.
  def load_user
    @user = params[:id] ? User.find(params[:id]) : User.new

    # User groups need to be processed separately due to complexity.
    permitted_params = user_params
    user_group_ids = permitted_params.delete(:user_group_ids)
    @user.user_groups = process_user_groups(user_group_ids)

    reset_password_method = permitted_params[:reset_password_method]
    if reset_password_method.present? && %w[enter enter_and_show].exclude?(reset_password_method)
      permitted_params.delete(:password)
      permitted_params.delete(:password_confirmation)
    end

    @user.assign_attributes(permitted_params)
  end

  def process_user_groups(user_group_ids)
    user_groups = []

    user_group_ids&.reject(&:blank?)&.each do |group_id|
      begin
        group = UserGroup.accessible_by(current_ability).find(group_id)
      rescue ActiveRecord::RecordNotFound
        group = nil
      end

      user_groups << (group || UserGroup.new(name: group_id, mission: current_mission))
    end
    user_groups
  end

  def user_params
    admin_only = [:admin] if can?(:adminify, @user)

    params.require(:user).permit(*admin_only, :name, :login, :birth_year,
      :gender, :gender_custom, :nationality, :email, :phone, :active, :phone2,
      :pref_lang, :notes, :password, :password_confirmation, :reset_password_method,
      user_group_ids: [], assignments_attributes: %i[role mission_id _destroy id])
  end
end
