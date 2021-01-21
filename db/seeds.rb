# frozen_string_literal: true

puts 'Seeding database ...'

# Ensure a root Setting exists.
Setting.build_default(nil).save! unless Setting.root.present?
