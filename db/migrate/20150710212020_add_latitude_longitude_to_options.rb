class AddLatitudeLongitudeToOptions < ActiveRecord::Migration[4.2]
  def change
    # -90 to 90 with six decimals
    add_column :options, :latitude, :decimal, precision: 8, scale: 6

    # -180 to 180 with six decimals
    add_column :options, :longitude, :decimal, precision: 9, scale: 6
  end
end
