# frozen_string_literal: true

# Models a group of 1. conditions or 2. other groups of conditions
# The nesting enables modeling something like this:
# (Q2 > 5 || Q3 == 7) && !(Q2 > 9 || Q3 == 1) && !(Q2 > 0 && Q3 == 2) && !(Q2 < 12 || Q3 > 5)
module Forms
  class ConditionGroup
    extend ActiveModel::Naming

    attr_accessor :members, :true_if, :negate, :name

    alias negate? negate

    delegate :empty?, to: :members

    def initialize(members: [], true_if: "all_met", negate: false, name: "Default")
      self.members = members
      self.true_if = true_if
      self.negate = negate
      self.name = name
    end
  end
end
