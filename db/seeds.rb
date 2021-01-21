# frozen_string_literal: true

# Ensure a root Setting exists.
puts 'Seeding'
Setting.build_default(nil).save! unless Setting.root.present?
