# frozen_string_literal: true

# Models a restriction on valid answers, similar to a Rails validation, but for NEMO forms.
class Constraint < ApplicationRecord
  include MissionBased
  include Replication::Replicable
  include Translatable

  translates :rejection_msg

  # Constraint ranks are currently not editable, but they provide a source of deterministic ordering
  # which is useful in tests and in UI consistency.
  acts_as_list column: :rank, scope: [:questioning_id]

  belongs_to :questioning, inverse_of: :constraints
  has_many :conditions, -> { by_rank }, as: :conditionable, inverse_of: :conditionable, dependent: :destroy

  before_create :inherit_mission

  validates :conditions, presence: true

  scope :by_rank, -> { order(:rank) }

  accepts_nested_attributes_for :conditions, allow_destroy: true, reject_if: :all_blank

  replicable child_assocs: [:conditions], dont_copy: %i[questioning_id],
             backward_assocs: [:questioning]

  # Duck type used for retrieving the main FormItem associated with this object, which is questioning.
  def base_item
    questioning
  end

  private

  def inherit_mission
    self.mission = questioning.mission
  end
end
