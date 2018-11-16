# frozen_string_literal: true

# Provides method for sending file to user via
# direct download or redirect
module Storage
  extend ActiveSupport::Concern

  URL_EXPIRE_TIME = 1.hour

  def send_attachment(attachment, params = {})
    style = params.delete(:style)
    if attachment.options[:storage] == "fog"
      redirect_to(attachment.expiring_url(URL_EXPIRE_TIME, style))
    else
      params[:type] ||= attachment.content_type
      params[:disposition] ||= "attachment"

      if style
        send_file(attachment.path(style), params)
      else
        send_file(attachment.path, params)
      end
    end
  end
end
