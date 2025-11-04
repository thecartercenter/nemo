# frozen_string_literal: true

module Notifiable
  extend ActiveSupport::Concern

  included do
    after_create :notify_creation, if: :should_notify_creation?
    after_update :notify_update, if: :should_notify_update?
  end

  private

  def notify_creation
    case self
    when Response
      NotificationService.notify_form_submission(self)
    when Form
      NotificationService.notify_form_published(self) if status_changed? && published?
    end
  end

  def notify_update
    case self
    when Response
      if reviewed_changed? && reviewed?
        NotificationService.notify_response_reviewed(self)
      end
    end
  end

  def should_notify_creation?
    case self
    when Response
      true
    when Form
      false # Forms are not published on creation
    else
      false
    end
  end

  def should_notify_update?
    case self
    when Response
      reviewed_changed? && reviewed?
    when Form
      status_changed? && published?
    else
      false
    end
  end
end