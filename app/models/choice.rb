class Choice < ActiveRecord::Base
  belongs_to(:answer, :inverse_of => :choices, :touch => true)
  belongs_to(:option, :inverse_of => :choices)

  delegate :name, :to => :option, :prefix => true
  delegate :has_coordinates?, :to => :option

  before_save :replicate_location_values

  def checked
    # Only explicitly false should return false.
    # This is so that the default value is true.
    @checked || @checked.nil?
  end
  alias_method :checked?, :checked

  def checked=(value)
    @checked = (value == true || value == '1')
  end

  private

  def replicate_location_values
    if has_coordinates?
      self.latitude = option.latitude
      self.longitude = option.longitude
    end
  end
end
