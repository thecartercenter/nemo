# frozen_string_literal: true

class RenderExistingLiveForms < ActiveRecord::Migration[6.1]
  def up
    Form.published.find_each { |f| ODK::FormRenderJob.perform_now(f) }
  end
end
