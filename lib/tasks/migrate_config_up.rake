# frozen_string_literal: true

# Tidies the .env file of some leftovers from the migration. Can be removed later, but should be harmless
# until then even if it's run over and over again.
namespace :config do
  desc "Clean up .env file."
  task migrate: :environment do
    env_path = Rails.root.join(".env.#{Rails.env}.local")
    lines = File.readlines(env_path)
    lines.reject! { |l| l =~ /(CONFIG ###|PAPERCLIP_STORAGE_TYPE)/ }
    File.open(env_path, "w") { |f| f.write(lines.join) }
    puts ".env file tidied"
  end
end
