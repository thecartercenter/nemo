require 'mission_based'

# defines all user abilities/permissions
class Ability
  include CanCan::Ability

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
  def initialize(user)
    if user
      # anybody can see the welcome page
      can :show, Welcome

      # anybody can edit self
      can :update, User, :id => user.id
      
      # anybody can generate map markers
      can :read, Marker
      
      # observer abilities
      if user.role?(:observer)
        # don't bother with these if the user is also an admin
        unless user.admin?
          # can view and export users in same mission
          can [:index, :read, :export], User, :assignments => {:mission_id => user.current_mission_id}
          
          # can access missions to which assigned
          can :read, Mission, :assignments => {:user_id => user.id}
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
        
        # can submit to any form with an authorized mission, regardless of the current_mission
        can :submit_to, Form do |form|
          user.accessible_missions.include?(form.mission)
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
      end
      
      # coordinator abilities
      if user.role?(:coordinator)
        # can manage users in current mission
        can [:create, :update], User, :assignments => {:mission_id => user.current_mission_id}
        
        # can create user batches
        can :manage, UserBatch
        
        # can destroy users only if they have only one mission and it's the current mission
        can :destroy, User do |other_user|
          other_user.assignments.count == 1 && other_user.assignments.first.mission_id == user.current_mission_id
        end
        
        # coord can manage these classes for the current mission
        [Form, FormType, Setting, Question, Option, OptionSet].each do |klass|
          can :manage, klass, :mission_id => user.current_mission_id
        end
        
        # coord can also manage Questionings (they don't have missions, only their parent questions/forms do)
        can :manage, Questioning, :question => {:mission_id => user.current_mission_id}
      end
      
      # admin abilities
      if user.admin?
        can :manage, User
        can :manage, Assignment
        can :manage, Mission
        
        # only admins can give/take admin (adminify) to/from others, but not from themselves
        cannot :adminify, User
        can :adminify, User, ["id != ?", user.id] do |other_user|
          user.id != other_user.id
        end
      end
    end
    
  end
end
