# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: %i[show mark_as_read destroy]

  def index
    @notifications = current_user.notifications
      .includes(:mission)
      .recent
      .paginate(page: params[:page], per_page: 20)

    @unread_count = current_user.notifications.unread.count
  end

  def show
    @notification.mark_as_read! unless @notification.read?
    render(json: @notification)
  end

  def mark_as_read
    @notification.mark_as_read!
    render(json: {success: true})
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)
    render(json: {success: true})
  end

  def unread_count
    count = current_user.notifications.unread.count
    render(json: {count: count})
  end

  def destroy
    @notification.destroy
    render(json: {success: true})
  end

  def destroy_all
    current_user.notifications.destroy_all
    render(json: {success: true})
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
