class AddPlaceTypeShortNames < ActiveRecord::Migration[4.2]
  def self.up
    add_column(:place_types, :short_name, :string)
    #PlaceType.all.each{|pt| pt.short_name = pt.name.match(/(^\w+)\/?/)[1].downcase; pt.save}
  end

  def self.down
    remove_column(:place_types, :short_name)
  end
end
