# defines all user abilities/permissions
class Ability
  include CanCan::Ability

  # Fix compatibility issue.
  # See https://github.com/GoodMeasuresLLC/draper-cancancan
  prepend Draper::CanCanCan

  attr_reader :user, :mission, :mode

  CRUD = [:new, :show, :edit, :create, :update, :destroy]

  # returns a list of roles that can be assigned by the given user
  def self.assignable_roles(user)
    # admins can assign any role
    if user.admin?
      User::ROLES
    # otherwise return everything below coordinator
    else
      User::ROLES[0...User::ROLES.index("coordinator")]
    end
  end

  # defines user's abilities
  def initialize(params)

    raise ArgumentError.new("Ability constructor accepts Hash only") unless params.is_a?(Hash)

    @user = params[:user]
    @mission = params[:mission]
    @mode = params[:mode]
    @mode ||= "mission" if @mission

    raise "Mission should be nil if mode is not 'mission'" if mode != "mission" && !mission.nil?

    if user

      # anybody can see the welcome page
      can :show, Welcome

      # anybody can show/edit self
      can [:show, :update], User, id: user.id

      # anybody can confirm their login
      can :confirm_login, UserSession

      # anybody can manage their own operations
      can :manage, Operation, creator_id: user.id

      # admin abilities that don't depend on a mission being set
      if user.admin?
        can :view, :admin_mode

        case mode
        when "admin"

          # standard objects, missions, settings, and all users are available in no-mission (admin) mode
          [Form, Questioning, FormItem, SkipRule, QingGroup, Condition, Question, OptionSet,
            OptionNode, Option, OptionSetImport, Tag, Tagging].each do |k|
            can :manage, k, mission_id: nil
          end
          can :manage, Mission
          can :manage, User
          can :manage, Assignment
          can :manage, Setting, mission_id: nil

        when "mission"

          # Admins can edit themselves in mission mode even if they're not currently assigned.
          can [:update, :login_instructions, :change_assignments], User, id: user.id

        end

        # admin can switch to any mission, regardless of mode
        can :switch_to, Mission

        # only admins can give/take admin (adminify) to/from others, but not from themselves
        cannot :adminify, User
        can :adminify, User, ["id != ?", user.id] do |other_user|
          user.id != other_user.id
        end

        # admin can manage any user's operations
        can :manage, Operation
      end

      # anybody can access missions to which assigned (but don't need this permission if admin)
      if !user.admin?
        can :switch_to, Mission, user.missions do |m|
          user.assignments.detect { |a| a.mission == m }
        end
      end

      # user can submit to any form if they are admin or can access the form's mission
      can :submit_to, Form do |form|
        user.admin? || user.assignments.detect { |a| a.mission == form.mission }
      end

      # all the rest of the permissions require a current mission to be set
      if mission

        # enumerator abilities
        if role_in_mission?(:enumerator)
          # can view and export users in same mission
          can [:index, :read, :show, :export], User, assignments: { mission_id: mission.id }

          can_read_all_reports_but_only_update_destroy_own

          can :regenerate_sms_auth_code, User do |u|
            u == user
          end

          # only need these abilities if not also a staffer
          unless role_in_mission?(:staffer)
            # can only see own responses
            can [:index, :read], Response, user_id: user.id, mission_id: mission.id

            # enumerators can only mark a form as 'incomplete' if the form permits it
            can :submit_incomplete, Response do |r|
              r.form.allow_incomplete?
            end

            # can only submit/edit/delete own responses, and only if mission is not locked
            unless mission.locked?
              can [:create, :update, :destroy, :modify_answers], Response,
                user_id: user.id, mission_id: mission.id, reviewed: false
            end
          end

          # can read published forms for the mission
          # only need this ability if not also a coordinator
          unless role_in_mission?(:coordinator)
            can [:index, :read, :download], Form, mission_id: mission.id, published: true
          end

        end

        # reviewer abilities
        if role_in_mission?(:reviewer)
          # only need these abilities if not also a staffer
          unless role_in_mission?(:staffer)
            can [:index, :review, :show, :edit, :update], Response, mission_id: mission.id
          end
        end

        # staffer abilities
        if role_in_mission?(:staffer)
          # can send broadcasts for the current mission
          can :manage, Broadcast, mission_id: mission.id

          can_read_all_reports_but_only_update_destroy_own
          can :export, Report::Report

          if mission.locked?
            # can index, read, export responses for a locked mission
            can [:index, :read, :export], Response, mission_id: mission.id
          else
            # can manage responses for anybody for an unlocked mission
            can :manage, Response, mission_id: mission.id

            # can do sms tests for an unlocked mission
            can :create, Sms::Test
          end

          can :regenerate_sms_auth_code, User

          # can view the dashboard (individual dashboard components are checked separately)
          can :view, :dashboard
        end

        # coordinator abilities
        if role_in_mission?(:coordinator)

          can :manage, Report::Report, mission_id: mission.id

          # permissions for locked missions only
          if mission.locked?
            can [:index, :read, :export], [Form, Question, OptionSet], mission_id: mission.id
            can :print, Form, mission_id: mission.id
            can :read, [Questioning, QingGroup, Option], mission_id: mission.id

          # permissions for non-locked mission
          else

            # can manage users in current mission
            # special change_assignments permission is given so that users cannot update their own assignments via edit profile
            can [:create, :update, :login_instructions, :change_assignments, :activate], User, assignments: { mission_id: mission.id }

            # can create user batches
            can :manage, UserBatch

            # can manage user groups
            can :manage, UserGroup, mission_id: mission.id
            can :manage, UserGroupAssignment

            # can destroy users only if they have only one mission and it's the current mission
            can [:bulk_destroy, :destroy], User do |other_user|
              other_user.assignments.count == 1 && other_user.assignments.first.mission_id == mission.id
            end

            # coord can manage these classes for the current mission
            [Form, OptionSet, OptionSetImport, Question, Questioning, FormItem, SkipRule,
              QingGroup, Option, Tag, Tagging].each do |klass|
              can :manage, klass, mission_id: mission.id
            end
          end

          # coord can manage these classes for the current mission even if locked
          [Setting, Sms::Message].each do |klass|
            can :manage, klass, mission_id: mission.id
          end

          # there is no Questioning index
          cannot :index, Questioning

          # there is no QingGroup index
          cannot :index, QingGroup
        end

        # Users can view/modify only their own API keys
        cannot :regenerate_api_key, User
        can :regenerate_api_key, User do |u|
          u == user
        end

        # Can't download forms for locked mission.
        cannot :download, Form if mission.locked?

      end # End if mission

      # Current user can bulk destroy questions
      can :bulk_destroy, Question

      # Can't change own assignments unless admin
      cannot :change_assignments, User, id: user.id unless user.admin?

      # Nobody can activate/deactivate or destroy themselves.
      cannot [:activate, :destroy], User, id: user.id
    end

    ###############
    # these permissions are user-independent

    # published forms and forms with responses can't be deleted
    cannot :destroy, Form do |f|
      f.published? || f.has_responses?
    end

    # only published forms can be downloaded
    cannot :download, Form, published: false

    cannot [:add_questions, :remove_questions, :reorder_questions], Form do |f|
      f.published?
    end

    # standard forms cannot be published and do not have versions, which are only assigned on publish
    cannot :publish, Form, is_standard: true

    cannot [:destroy, :update, :update_core], Questioning do |q|
      q.published?
    end

    # BUT can update questioning (though not its core) if can update related question
    # we need this because questions are updated via questionings
    # so a question (though not its core) may be updatable even though it's published
    # and we need to allow access to that question via the questioning index
    can :update, Questioning do |q|
      can? :update, q.question
    end

    cannot :destroy, Questioning do |q|
      q.has_answers?
    end

    # update_core refers to the core fields: question type, option set, constraints
    cannot :update_core, Question do |q|
      q.published? || q.has_answers?
    end

    # update_code refers to the question code attribute
    cannot :update_code, Question do |q|
      q.standard_copy?
    end

    cannot :destroy, Question do |q|
      q.published? || q.has_answers?
    end

    # we need these specialized permissions because option names/hints are updated via option set
    cannot [:add_options, :remove_options, :reorder_options], OptionSet do |o|
      o.published?
    end

    cannot :destroy, OptionSet do |o|
      o.has_answers? || o.has_questions? || o.published?
    end

    # nobody can update an operation
    cannot :update, Operation

    # operation's can't be destroyed while their underlying job is in progress
    cannot :destroy, Operation do |op|
      op.provider_job_id.present? && Delayed::Job.exists?(op.provider_job_id)
    end

    # nobody can assign anybody to a locked mission
    cannot :assign_to, Mission, locked: true

    # nobody can edit assignments for a locked mission
    cannot [:create, :update, :destroy], Assignment, mission: {locked: true}
  end

  def to_s
    "User: #{@user.try(:login) || '[None]'}, Mode: #{@mode}, Mission: #{@mission.try(:name) || '[None]'}"
  end

  private

  def role_in_mission?(role_name)
    user.role?(role_name, mission)
  end

  def can_read_all_reports_but_only_update_destroy_own
    can [:read, :create], Report::Report, mission_id: mission.id
    can [:update, :destroy], Report::Report, mission_id: mission.id, creator_id: user.id
  end
end
