# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    # Admin: full access
    if user.admin?
      can :manage, :all
      can :access, :admin
      return
    end

    # Guest + all: public widget submissions
    can :create, FeedbackSubmission
    can :create, Suggestion
    can :create, OptIn

    # Public: plan listing
    can :read, Plan

    return if user.new_record?

    # Logged-in: own resources
    can :manage, Location, user_id: user.id
    can :manage, FeedbackSubmission, location: { user_id: user.id }
    can :read, FeedbackSubmission
    can :manage, OptIn, location: { user_id: user.id }
    can :read, OptIn
    can :manage, Suggestion, location: { user_id: user.id }
    can :read, Suggestion

    # Logged-in: dashboard and onboarding
    can :read, :dashboard
    can %i[read update], :onboarding

    # Logged-in: profile and billing
    can :manage, User, id: user.id
    can :create, :checkout_session
    can :create, :billing_portal_session
    can :manage, :email_preferences
  end
end
