# frozen_string_literal: true

class RenderExistingLiveForms2 < ActiveRecord::Migration[6.1]
  def up
    puts "Rendering #{Form.published.count} forms..."
    Form.published.find_each do |f|
      puts "Rendering #{f.name}..."
      ODK::FormRenderJob.perform_now(f)
    end
  end
end
