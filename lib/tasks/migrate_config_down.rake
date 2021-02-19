# frozen_string_literal: true

# Undoes the additions from `config:migrate`.
namespace :config do
  desc "UN-migrate config files from new system."
  task "migrate:down": :environment do |_args|
    env_path = Rails.root.join(".env.#{Rails.env}.local")
    existing = File.read(env_path)
    bits = existing.split(/\s*### BEGIN MIGRATED CONFIG ###.+### END MIGRATED CONFIG ###\s*/m)
    existing = bits.map(&:strip).join("\n")
    File.open(env_path, "w") { |f| f.write("#{existing}\n") }

    puts "Config UN-migrated."
  end
end
