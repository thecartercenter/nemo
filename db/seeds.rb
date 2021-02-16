# frozen_string_literal: true

puts "Seeding database ..." # rubocop:disable Rails/Output

# Ensure a root Setting exists.
Setting.build_default(mission: nil).save! if Setting.root.blank?
