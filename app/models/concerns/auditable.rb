# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do
    after_create :log_create
    after_update :log_update
    after_destroy :log_destroy
  end

  private

  def log_create
    return unless should_log_activity?

    AuditLog.log_action(
      current_user,
      :create,
      self.class.name,
      resource_id: id,
      changes: changes_to_log,
      metadata: auditable_metadata
    )
  end

  def log_update
    return unless should_log_activity?
    return unless saved_changes.any?

    AuditLog.log_action(
      current_user,
      :update,
      self.class.name,
      resource_id: id,
      changes: changes_to_log,
      metadata: auditable_metadata
    )
  end

  def log_destroy
    return unless should_log_activity?

    AuditLog.log_action(
      current_user,
      :destroy,
      self.class.name,
      resource_id: id,
      changes: changes_to_log,
      metadata: auditable_metadata
    )
  end

  def should_log_activity?
    # Only log if we have a current user and it's not a system operation
    current_user.present? && !system_operation?
  end

  def system_operation?
    # Override in models that perform system operations
    false
  end

  def changes_to_log
    # Filter out sensitive fields and system fields
    sensitive_fields = %w[password password_confirmation password_salt crypted_password]
    system_fields = %w[created_at updated_at id]

    changes = saved_changes || {}
    changes.reject do |field, _|
      sensitive_fields.include?(field) || system_fields.include?(field)
    end
  end

  def auditable_metadata
    # Override in models to add specific metadata
    {}
  end

  def current_user
    # Try to get current user from various sources
    Thread.current[:current_user] ||
      RequestStore.store[:current_user] ||
      (respond_to?(:user) ? user : nil)
  end
end
