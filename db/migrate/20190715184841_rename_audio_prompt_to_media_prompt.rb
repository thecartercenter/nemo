# frozen_string_literal: true

class RenameAudioPromptToMediaPrompt < ActiveRecord::Migration[5.2]
  def change
    rename_column :questions, :audio_prompt_content_type, :media_prompt_content_type
    rename_column :questions, :audio_prompt_file_name, :media_prompt_file_name
    rename_column :questions, :audio_prompt_file_size, :media_prompt_file_size
    rename_column :questions, :audio_prompt_updated_at, :media_prompt_updated_at
  end
end
