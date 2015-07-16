class OptionSetImport
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::AttributeAssignment

  attr_accessor :mission_id, :name, :file

  validates(:mission_id, presence: true)
  validates(:name, presence: true)
  validates(:file, presence: true)

  def initialize(attributes={})
    assign_attributes(attributes)
  end

  def persisted?
    false
  end

  def mission
    @mission ||= Mission.find(mission_id) if mission_id.present?
  end

  def mission=(mission)
    self.mission_id = mission.try(:id)
    @mission = mission
  end
end
