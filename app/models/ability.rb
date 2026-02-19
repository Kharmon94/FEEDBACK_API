# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.admin?
      can :manage, :all
      can :access, :admin
      return
    end

    can :create, FeedbackSubmission
    can :create, Suggestion
    can :create, OptIn
    can :read, Location

    return if user.new_record?

    can :manage, Location, user_id: user.id
    can :manage, FeedbackSubmission, location: { user_id: user.id }
    can :read, FeedbackSubmission # for index
    can :read, OptIn # for index; controller scopes to user's locations
    can :manage, Suggestion, location: { user_id: user.id }
    can :read, Suggestion # for index
    can :read, :dashboard
    can %i[read update], :onboarding
  end
end
