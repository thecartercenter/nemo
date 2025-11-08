# frozen_string_literal: true

class WebhookService
  def self.trigger_event(event, data, mission = nil)
    return unless mission

    webhooks = Webhook.active.for_event(event).where(mission: mission)
    
    webhooks.find_each do |webhook|
      webhook.trigger(event, data)
    end
  end

  def self.trigger_form_created(form)
    payload = {
      form: {
        id: form.id,
        name: form.name,
        status: form.status,
        created_at: form.created_at.iso8601,
        updated_at: form.updated_at.iso8601
      }
    }

    if (creator = user_payload(form.try(:creator)))
      payload[:creator] = creator
    end

    trigger_event('form.created', payload, form.mission)
  end

  def self.trigger_form_updated(form)
    payload = {
      form: {
        id: form.id,
        name: form.name,
        status: form.status,
        created_at: form.created_at.iso8601,
        updated_at: form.updated_at.iso8601
      }
    }

    if (updater = user_payload(form.try(:updater)))
      payload[:updater] = updater
    end

    trigger_event('form.updated', payload, form.mission)
  end

  def self.trigger_form_published(form)
    trigger_event('form.published', {
      form: {
        id: form.id,
        name: form.name,
        status: form.status,
        published_at: form.published_changed_at&.iso8601
      }
    }, form.mission)
  end

  def self.trigger_response_created(response)
    trigger_event('response.created', {
      response: {
        id: response.id,
        shortcode: response.shortcode,
        source: response.source,
        incomplete: response.incomplete?,
        created_at: response.created_at.iso8601
      },
      form: {
        id: response.form.id,
        name: response.form.name
      },
      submitter: {
        id: response.user.id,
        name: response.user.name
      }
    }, response.mission)
  end

  def self.trigger_response_updated(response)
    trigger_event('response.updated', {
      response: {
        id: response.id,
        shortcode: response.shortcode,
        source: response.source,
        incomplete: response.incomplete?,
        updated_at: response.updated_at.iso8601
      },
      form: {
        id: response.form.id,
        name: response.form.name
      },
      updater: user_payload(response.user)
    }, response.mission)
  end

  def self.trigger_response_submitted(response)
    trigger_event('response.submitted', {
      response: {
        id: response.id,
        shortcode: response.shortcode,
        source: response.source,
        submitted_at: response.updated_at.iso8601
      },
      form: {
        id: response.form.id,
        name: response.form.name
      },
      submitter: {
        id: response.user.id,
        name: response.user.name
      }
    }, response.mission)
  end

  def self.trigger_response_reviewed(response)
    trigger_event('response.reviewed', {
      response: {
        id: response.id,
        shortcode: response.shortcode,
        reviewed: response.reviewed?,
        reviewed_at: response.updated_at.iso8601
      },
      form: {
        id: response.form.id,
        name: response.form.name
      },
      reviewer: user_payload(response.reviewer)
    }, response.mission)
  end

  def self.trigger_user_created(user, mission)
    trigger_event('user.created', {
      user: {
        id: user.id,
        name: user.name,
        login: user.login,
        email: user.email,
        created_at: user.created_at.iso8601
      }
    }, mission)
  end

  def self.trigger_user_assigned(user, mission, role)
    trigger_event('user.assigned', {
      user: {
        id: user.id,
        name: user.name,
        login: user.login,
        email: user.email
      },
      assignment: {
        mission_id: mission.id,
        mission_name: mission.name,
        role: role,
        assigned_at: Time.current.iso8601
      }
    }, mission)
  end

  def self.trigger_data_export_completed(export_type, filename, user, mission)
    trigger_event('data_export.completed', {
      export: {
        type: export_type,
        filename: filename,
        completed_at: Time.current.iso8601
      },
      user: {
        id: user.id,
        name: user.name
      }
    }, mission)
  end

  def self.trigger_notification_sent(notification)
    trigger_event('notification.sent', {
      notification: {
        id: notification.id,
        type: notification.type,
        title: notification.title,
        sent_at: notification.created_at.iso8601
      },
      user: user_payload(notification.user)
    }, notification.mission)
  end

  def self.verify_webhook_signature(payload, signature, secret)
    return false if secret.blank? || signature.blank?

    expected_signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, payload)}"
    ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
  end

  def self.user_payload(user)
    return if user.blank?

    {
      id: user.id,
      name: user.name
    }
  end

  private_class_method :user_payload
end