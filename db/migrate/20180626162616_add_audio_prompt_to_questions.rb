# frozen_string_literal: true

# Add audio prompt to question table for paperclip
class AddAudioPromptToQuestions < ActiveRecord::Migration[5.1]
  def up
    add_attachment :questions, :audio_prompt
  end

  def down
    remove_attachment :questions, :audio_prompt
  end
end
