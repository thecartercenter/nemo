# frozen_string_literal: true

module Ancestry
  # By default, the ancestry gem validates against a pattern assuming numeric ids,
  # this pattern checks for uuid-like ids instead.
  ANCESTRY_PATTERN = %r{\A[\w\-]+(/[\w\-]+)*\z}.freeze
end
