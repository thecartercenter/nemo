# One part of a Question with a multilevel OptionSet (e.g. State, Species, etc.)
class Subquestion < Questionable
  belongs_to(:question, :foreign_key => 'parent_id')
  belongs_to(:option_level)

  # references to parent Question and OptionLevel are mandatory
  validates(:option_level, :question, :presence => true)

  replicable :parent_assoc => :question, :dont_copy => :option_level_id
end