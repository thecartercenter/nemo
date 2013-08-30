# defines all user abilities/permissions
class Ability
  include CanCan::Ability
  
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
  def initialize(user, admin_mode = false)
    if user

      # anybody can see the welcome page
      can :show, Welcome

      # anybody can edit self
      can :update, User, :id => user.id
      
      # anybody can generate map markers
      can :read, Marker

      # admin abilities that don't depend on a mission being set
      if user.admin?
        can :manage, User
        can :manage, Assignment
        can :manage, Mission
        can :view, :admin_mode

        # standard objects are available as long as the user is no-mission (admin) mode
        if admin_mode
          [Form, Questioning, Condition, Question, OptionSet, Optioning, Option].each do |k|
            can :manage, k, :is_standard => true
          end
        end

        # only admins can give/take admin (adminify) to/from others, but not from themselves
        cannot :adminify, User
        can :adminify, User, ["id != ?", user.id] do |other_user|
          user.id != other_user.id
        end
      end
      
      # anybody can access missions to which assigned (but don't need this permission if admin)
      if !user.admin?
        can :read, Mission, Mission.active_for_user(user) do |mission|
          user.assignments.detect{|a| a.mission == mission}
        end
      end
      
      # user can submit to any form if they can access the form's mission
      can :submit_to, Form do |form|
        user.accessible_missions.include?(form.mission)
      end
      
      # all the rest of the permissions require a current mission to be set
      if user.current_mission_id
      
        # observer abilities
        if user.role?(:observer)
          # don't bother with these if the user is also an admin
          unless user.admin?
            # can view and export users in same mission
            can [:index, :read, :export], User, :assignments => {:mission_id => user.current_mission_id}
          end
        
          # can submit responses for themselves only, and can only manage unreviewed responses
          # only need this ability if not also a staffer
          unless user.role?(:staffer)
            can [:index, :read, :export, :create, :update, :destroy], Response, 
              :user_id => user.id, :mission_id => user.current_mission_id, :reviewed => false
          end
        
          # can read published forms for the mission
          # only need this ability if not also a coordinator
          unless user.role?(:coordinator)
            can [:index, :read], Form, :mission_id => user.current_mission_id, :published => true
          end
        
        end
      
        # staffer abilities
        if user.role?(:staffer)
          # can send broadcasts for the current mission
          can :manage, Broadcast, :mission_id => user.current_mission_id
        
          # can do reports for the current mission
          can :manage, Report::Report, :mission_id => user.current_mission_id
        
          # can manage responses for anybody
          can :manage, Response, :mission_id => user.current_mission_id
        
          # can do sms tests
          can :create, Sms::Test

          # can view the dashboard (individual dashboard components are checked separately)
          can :view, :dashboard
        end
      
        # coordinator abilities
        if user.role?(:coordinator)
          # can manage users in current mission
          can [:create, :update, :login_instructions], User, :assignments => {:mission_id => user.current_mission_id}
        
          # can create user batches
          can :manage, UserBatch
        
          # can destroy users only if they have only one mission and it's the current mission
          can :destroy, User do |other_user|
            other_user.assignments.count == 1 && other_user.assignments.first.mission_id == user.current_mission_id
          end
        
          # coord can manage these classes for the current mission
          [Form, Setting, Question, Option, OptionSet, Sms::Message].each do |klass|
            can :manage, klass, :mission_id => user.current_mission_id
          end
        
          # coord can also manage Questionings (they don't have missions, only their parent questions/forms do)
          can :manage, Questioning, :question => {:mission_id => user.current_mission_id}
          # there is no Questioning index though
          cannot :index, Questioning
        end
      end
    end
    
  end
end
