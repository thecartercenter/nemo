# frozen_string_literal: true

# By default, the ancestry gem validates against a pattern assuming numeric ids,
# this changes the constant to check for uuid-like ids instead
#
# it does this in a roundabout way because constants aren't supposed to change
module Ancestry
  send :remove_const, :ANCESTRY_PATTERN
  const_set :ANCESTRY_PATTERN, %r{\A[\w\-]+(/[\w\-]+)*\z}
end
