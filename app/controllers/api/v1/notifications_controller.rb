# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < BaseController
      before_action :set_notification, only: %i[show mark_as_read destroy]

      def index
        notifications = current_user.notifications
          .includes(:mission)
          .recent

        # Apply filters
        notifications = notifications.where(mission: current_mission) if current_mission
        notifications = notifications.where(type: params[:type]) if params[:type].present?
        notifications = notifications.where(read: params[:read]) if params[:read].present?

        # Pagination
        notifications = notifications.paginate(paginate_params)

        render(json: success_response({
          notifications: notifications.map { |notification| notification_json(notification) },
          unread_count: current_user.notifications.unread.count,
          pagination: {
            current_page: notifications.current_page,
            total_pages: notifications.total_pages,
            total_count: notifications.total_entries,
            per_page: notifications.per_page
          }
        }))
      end

      def show
        @notification.mark_as_read! unless @notification.read?

        render(json: success_response(notification_json(@notification)))
      end

      def mark_as_read
        @notification.mark_as_read!

        render(json: success_response({}, "Notification marked as read"))
      end

      def mark_all_as_read
        current_user.notifications.unread.update_all(read: true)

        render(json: success_response({}, "All notifications marked as read"))
      end

      def unread_count
        count = current_user.notifications.unread.count

        render(json: success_response({count: count}))
      end

      def destroy
        @notification.destroy

        render(json: success_response({}, "Notification deleted"))
      end

      def destroy_all
        current_user.notifications.destroy_all

        render(json: success_response({}, "All notifications deleted"))
      end

      private

      def set_notification
        @notification = current_user.notifications.find(params[:id])
      end

      def notification_json(notification)
        {
          id: notification.id,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          read: notification.read?,
          data: notification.data,
          mission: if notification.mission
                     {
                       id: notification.mission.id,
                       name: notification.mission.name,
                       shortcode: notification.mission.shortcode
                     }
                   end,
          created_at: notification.created_at.iso8601,
          updated_at: notification.updated_at.iso8601
        }
      end
    end
  end
end
