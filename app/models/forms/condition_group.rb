module Forms
  class ConditionGroup
    attr_accessor :members, :true_if, :negate
    alias_method :negate?, :negate

    delegate :empty?, to: :members

    def initialize(members: [], true_if: "all_met", negate: false)
      self.members = members
      self.true_if = true_if
      self.negate = negate
    end
  end
end
