# frozen_string_literal: true

# Defines all user abilities/permissions
class Ability
  include CanCan::Ability

  # Fix compatibility issue.
  # See https://github.com/GoodMeasuresLLC/draper-cancancan
  prepend Draper::CanCanCan

  attr_accessor :user, :mission, :mode

  CRUD = %i[new show edit create update destroy].freeze

  # Returns a list of roles that can be assigned by the given user
  def self.assignable_roles(user)
    # Admins can assign any role. Else everything below coordinator.
    user.admin? ? User::ROLES : User::ROLES[0...User::ROLES.index("coordinator")]
  end

  def initialize(params)
    raise ArgumentError, "Ability constructor accepts Hash only" unless params.is_a?(Hash)

    self.user = params[:user]
    self.mission = params[:mission]
    self.mode = params[:mode]
    self.mode ||= "mission" if mission

    if mode != "mission" && mission.present?
      raise ArgumentError, "Mission should be nil if mode is not 'mission'"
    end

    user_dependent_permissions if user
    user_independent_permissions
  end

  def to_s
    "User: #{@user.try(:login) || '[None]'}, Mode: #{@mode}, Mission: #{@mission.try(:name) || '[None]'}"
  end

  private

  #########################################
  # Deprecation of :manage
  # ---------------------------------
  # CanCanCan best practice seems to indicate it's better to give permissions than to take them away.
  # Using :manage impedes this because it grants permissions on all actions.
  # This means one has to use cannot to revoke some of those later in the file if necessary.
  # Having multiple places where a permission is defined (given, taken away, given again) is confusing
  # and can prevent the definition of a scope for use with accessible_by.
  # So we are moving away from using :manage, preferring to grant permissions explicitly instead.
  #
  # When refactoring away from :manage, be sure to account for all permissions that may be getting checked
  # at runtime. Places to look are:
  # - Throughout this file
  # - Throughout this gist https://gist.github.com/cooperka/47f50bd17f854e25ec179b382d9e9e4f
  #   which was created by grepping:
  #     - Throughout the app by grepping can?, cannot?, authorize!, and accessible_by
  #     - The routes file (are there any custom actions combined authorize_resource?-if so, consider using
  #       skip_authorize_resource and using a stock permission unless the custom one is really needed.)

  def user_dependent_permissions
    can(:show, Welcome)
    can(%i[show update], User, id: user.id)
    can(:confirm_login, UserSession)
    can(%i[manage download], Operation, creator_id: user.id)
    can(:submit_to, Form) { |f| user.admin? || user.assignments.detect { |a| a.mission == f.mission } }

    user.admin? ? admin_permissions : non_admin_permissions
    mission_dependent_permissions if mission

    cannot(:change_assignments, User, id: user.id) unless user.admin?

    # Can only modify own API key.
    cannot(:regenerate_api_key, User)
    can(:regenerate_api_key, User) { |u| u == user }
  end

  def admin_permissions
    if mode == "admin"
      # Standard objects, missions, settings, and all users are available in no-mission (admin) mode
      [Form, Questioning, FormItem, SkipRule, QingGroup, Condition, OptionSet,
       OptionNode, Option, OptionSets::Import, Setting, Tag, Tagging].each do |k|
        can(:manage, k, mission_id: nil)
      end
      # This is intentionally redundant with `manage` as we're slowly migrating to explicit permissions.
      can(:update_core, OptionSet, mission_id: nil)
      cannot(:change_status, Form, &:standard?)

      can(%i[read create update update_code update_core export bulk_destroy],
        Question, mission_id: nil)
      can(:destroy, Question) { |q| !q.published? && !q.data? }

      can(:manage, Mission)
      can(:manage, User)
      cannot(%i[activate destroy], User, id: user.id)
      can(:manage, Assignment)
    elsif mode == "mission"
      # Admins can edit themselves in mission mode even if they're not currently assigned.
      can(%i[update login_instructions change_assignments], User, id: user.id)
    end

    # Only admins can give/take admin (adminify) to/from others, but not from themselves
    cannot(:adminify, User)
    can(:adminify, User, ["id != ?", user.id]) do |other_user|
      user.id != other_user.id
    end

    can(:view, :admin_mode)
    can(:switch_to, Mission)
    can(:manage, Operation)
  end

  # Permissions that only non-admins need.
  def non_admin_permissions
    can(:switch_to, Mission, user.missions) { |m| user.assignments.detect { |a| a.mission == m } }
  end

  def mission_dependent_permissions
    can(%i[possible_submitters possible_reviewers], Response, mission_id: mission.id)
    can(%i[index possible_groups], UserGroup, mission_id: mission.id)

    enumerator_permissions if user_has_this_or_higher_role_in_mission?(:enumerator)
    reviewer_permissions if user_has_this_or_higher_role_in_mission?(:reviewer)
    staffer_permissions if user_has_this_or_higher_role_in_mission?(:staffer)
    coordinator_permissions if user_has_this_or_higher_role_in_mission?(:coordinator)

    cannot(:download, Form) if mission.locked?
  end

  def coordinator_permissions
    can(:manage, Report::Report, mission_id: mission.id)

    if mission.locked?
      can(%i[index read export], [Form, Question, OptionSet], mission_id: mission.id)
      can(:print, Form, mission_id: mission.id)
      can(:read, [Questioning, QingGroup, Option], mission_id: mission.id)
    else
      # Special change_assignments permission is given so that
      # users cannot update their own assignments via edit profile.
      can(%i[create update login_instructions change_assignments activate bulk_destroy], User,
        assignments: {mission_id: mission.id})
      cannot(:activate, User, id: user.id)

      can(:manage, UserImport)
      can(:manage, UserGroup, mission_id: mission.id)
      can(:manage, UserGroupAssignment)

      # Can destroy users only if not self, they have only one mission, and it's current mission.
      can(:destroy, User, User.assigned_only_to(mission).where.not(id: user.id)) do |other|
        other.id != user.id &&
          other.assignments.count == 1 &&
          other.assignments.first.mission_id == mission.id
      end

      [Form, OptionSet, OptionSets::Import, Questioning, FormItem, SkipRule,
       QingGroup, OptionNode, Option, Tag, Tagging].each do |klass|
        can(:manage, klass, mission_id: mission.id)
      end
      can(:condition_form, Constraint, mission_id: mission.id)
      can(:change_status, Form, mission_id: mission.id)
      can(:update_core, OptionSet, mission_id: mission.id)

      can(%i[read create update update_code update_core export bulk_destroy],
        Question, mission_id: mission.id)
      can(:destroy, Question) { |q| q.mission_id == mission.id && !q.published? && !q.data? }
    end

    # Can manage these classes for the current mission even if locked
    [Setting, Sms::Message].each { |klass| can(:manage, klass, mission_id: mission.id) }
  end

  def staffer_permissions
    # can send broadcasts for the current mission
    can(:manage, Broadcast, mission_id: mission.id)

    can(%i[read create], Report::Report, mission_id: mission.id)
    can(%i[update destroy], Report::Report, mission_id: mission.id, creator_id: user.id)
    can(:export, Report::Report)

    # Deliberately using :manage here because we are treating OData as a black box.
    # Given that it is an engine, explicitly listing its controller actions seems wrong.
    # They are all in service of the same outcome, sending data.
    # If you can do one you should be able to do all.
    #
    # It is important for now that this permission only be granted to roles that can see
    # all responses in a mission since we are not consulting accessible_by when loading Responses.
    # This is due to the way the OData engine does this.
    can(:manage, :o_data)

    if mission.locked?
      can(%i[index read export], Response, mission_id: mission.id)
    else
      can(:manage, Response, mission_id: mission.id)
      can(:create, Sms::Test)
    end

    can(:regenerate_sms_auth_code, User)
    can(:view, :dashboard)
  end

  def reviewer_permissions
    # only need these abilities if not also a staffer
    return if user_has_this_or_higher_role_in_mission?(:staffer)
    can(%i[index review show edit update], Response, mission_id: mission.id)
  end

  def enumerator_permissions
    can(%i[index read show export], User, assignments: {mission_id: mission.id})

    can(%i[read create], Report::Report, mission_id: mission.id)
    can(%i[update destroy], Report::Report, mission_id: mission.id, creator_id: user.id)

    can(:regenerate_sms_auth_code, User) { |u| u == user }
    can(:login_instructions, User, id: user.id)

    # only need these abilities if not also a staffer
    unless user_has_this_or_higher_role_in_mission?(:staffer)
      can(%i[index read], Response, user_id: user.id, mission_id: mission.id)

      # enumerators can only mark a form as 'incomplete' if the form permits it
      can(:submit_incomplete, Response) { |r| r.form.allow_incomplete? }

      # can only submit/edit/delete own responses, and only if mission is not locked
      unless mission.locked?
        can(%i[create update destroy modify_answers], Response,
          user_id: user.id, mission_id: mission.id, reviewed: false)
      end
    end

    # Only need this ability if not also a coordinator
    # Duplicating the lines for each of live and paused status to achieve 'OR'.
    return if user_has_this_or_higher_role_in_mission?(:coordinator)
    can(%i[index show download], Form, mission_id: mission.id, status: "live")
  end

  # Should be called after other main methods as it restricts some permissions granted earlier.
  def user_independent_permissions
    cannot(:destroy, Form) { |f| f.not_draft? || f.has_responses? }
    cannot(:download, Form, status: "draft")
    cannot(%i[add_questions remove_questions reorder_questions], Form, &:not_draft?)

    cannot(%i[destroy update update_core], Questioning, &:published?)

    # BUT can update questioning (though not its core) if can update related question
    # we need this because questions are updated via questionings
    # so a question (though not its core) may be updatable even though it's published
    # and we need to allow access to that question via the questioning index
    can(:update, Questioning) { |q| can?(:update, q.question) }
    cannot(:destroy, Questioning, &:data?)

    # update_core refers to the core fields: question type, option set, constraints
    cannot(:update_core, Question) { |q| q.published? || q.data? }
    cannot(:update_code, Question, &:standard_copy?) # question code attribute

    # we need these specialized permissions because option names/hints are updated via option set
    cannot(%i[add_options remove_options reorder_options], OptionSet, &:published?)
    cannot(:destroy, OptionSet) { |o| o.data? || o.in_use? || o.published? }
    cannot(:destroy, OptionNode) { |n| n.data? || n.in_use? }

    # operations can't be destroyed while their underlying job is in progress
    cannot(:destroy, Operation) do |op|
      op.provider_job_id.present? && Delayed::Job.exists?(op.provider_job_id)
    end

    cannot(:assign_to, Mission, locked: true)
    cannot(%i[create update destroy], Assignment, mission: {locked: true})
  end

  def user_has_this_or_higher_role_in_mission?(role_name)
    user.role?(role_name, mission)
  end
end
