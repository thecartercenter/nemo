class GenerateTokensForExistingMediaObjects < ActiveRecord::Migration[4.2]
  def up
    Media::Object.find_each do |media_object|
      media_object.update_attributes(token: SecureRandom.hex)
    end
  end

  def down
    Media::Object.update_all(token: nil)
  end
end
