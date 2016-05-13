class GenerateTokensForExistingMediaObjects < ActiveRecord::Migration
  def up
    Media::Object.find_each do |media_object|
      media_object.update_attributes(token: SecureRandom.hex)
    end
  end

  def down
    Media::Object.update_all(token: nil)
  end
end
