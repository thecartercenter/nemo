# frozen_string_literal: true

class NotificationService
  def self.notify_form_submission(response)
    form = response.form
    mission = response.mission
    
    # Notify mission coordinators and staffers
    mission.users.joins(:assignments)
           .where(assignments: { role: %w[coordinator staffer] })
           .find_each do |user|
      Notification.create_for_user(
        user,
        'form_submission',
        "New form submission: #{form.name}",
        message: "A new response was submitted for form '#{form.name}' by #{response.user.name}",
        data: {
          response_id: response.id,
          form_id: form.id,
          form_name: form.name,
          submitter_name: response.user.name,
          submitted_at: response.created_at
        },
        mission: mission
      )
    end
  end

  def self.notify_form_published(form)
    mission = form.mission
    
    # Notify all mission users
    Notification.create_for_mission_users(
      mission,
      'form_published',
      "Form published: #{form.name}",
      message: "The form '#{form.name}' has been published and is now available for data collection",
      data: {
        form_id: form.id,
        form_name: form.name,
        published_at: form.published_changed_at
      }
    )
  end

  def self.notify_response_reviewed(response)
    form = response.form
    mission = response.mission
    
    # Notify the submitter
    Notification.create_for_user(
      response.user,
      'response_reviewed',
      "Response reviewed: #{form.name}",
      message: "Your response for form '#{form.name}' has been reviewed",
      data: {
        response_id: response.id,
        form_id: form.id,
        form_name: form.name,
        reviewed_at: response.updated_at,
        reviewer_name: response.reviewer&.name
      },
      mission: mission
    )
  end

  def self.notify_user_assigned(user, mission, role)
    Notification.create_for_user(
      user,
      'user_assigned',
      "Assigned to mission: #{mission.name}",
      message: "You have been assigned to the mission '#{mission.name}' as a #{role}",
      data: {
        mission_id: mission.id,
        mission_name: mission.name,
        role: role,
        assigned_at: Time.current
      },
      mission: mission
    )
  end

  def self.notify_data_export_complete(user, export_type, filename)
    Notification.create_for_user(
      user,
      'data_export_complete',
      "Data export complete: #{export_type}",
      message: "Your #{export_type} export has been completed. File: #{filename}",
      data: {
        export_type: export_type,
        filename: filename,
        completed_at: Time.current
      }
    )
  end

  def self.notify_system_alert(mission, title, message, data = {})
    Notification.create_for_mission_users(
      mission,
      'system_alert',
      title,
      message: message,
      data: data.merge(alert_at: Time.current)
    )
  end

  def self.notify_mission_update(mission, title, message, data = {})
    Notification.create_for_mission_users(
      mission,
      'mission_update',
      title,
      message: message,
      data: data.merge(updated_at: Time.current)
    )
  end
end