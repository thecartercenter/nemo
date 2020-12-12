# frozen_string_literal: true

# Provides method for sending file to user via
# direct download or redirect
module Storage
  extend ActiveSupport::Concern

  def send_attachment(attachment, params = {})
    local = Rails.configuration.active_storage.service == :local
    style = params.delete(:style)

    if params[:disposition] == "inline"
      attachment = attachment.variant(resize: Media::Image::SIZE_THUMB).processed if style == "thumb"
      # What a mess, there must be a better way to handle local/cloud original/variant...
      url = if local
              attachment.respond_to?(:variation) ? rails_representation_url(attachment) : rails_blob_path(attachment)
            else
              attachment.service_url
            end
      return redirect_to(url)
    end

    default_params = {filename: attachment.filename.to_s,
                      content_type: attachment.content_type,
                      disposition: "attachment"}
    send_data(attachment.download, default_params.merge(params))
  end
end
