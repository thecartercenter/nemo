# frozen_string_literal: true

# Represents a hierarchical connection between two ResponseNodes.
# This class itself is only used to hold clone information.
class AnswerHierarchy < ApplicationRecord
  clone_options follow: []
end
