class AddRedundantLinksToPlaces < ActiveRecord::Migration[4.2]
  def self.up
    add_column(:places, :point_id, :integer)
    add_column(:places, :address_id, :integer)
    add_column(:places, :locality_id, :integer)
    add_column(:places, :state_id, :integer)
    add_column(:places, :country_id, :integer)

    # populate
    # Place.all.each do |p|
    #   cont = p
    #   while !cont.nil? do
    #     puts "Setting #{p.full_name}'s #{cont.place_type.short_name}_id to #{cont.id}"
    #     p.send("#{cont.place_type.short_name}_id=", cont.id)
    #     cont = cont.container
    #   end
    #   p.save(:validate => false)
    # end
  end

  def self.down
    #remove_column(:places, :point_id)
    remove_column(:places, :address_id)
    remove_column(:places, :locality_id)
    remove_column(:places, :state_id)
    remove_column(:places, :country_id)
  end
end
