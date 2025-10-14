# frozen_string_literal: true

require "fileutils"

class RenameAudioPromptsDir < ActiveRecord::Migration[5.2]
  OLD = "uploads/questions/audio_prompts"
  NEW = "uploads/questions/media_prompts"

  def up
    FileUtils.mv(OLD, NEW) if File.exist?(OLD)
  end

  def down
    FileUtils.mv(NEW, OLD) if File.exist?(NEW)
  end
end
