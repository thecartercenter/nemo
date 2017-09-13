class AddAltitudeAndAccuracyToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :altitude, :decimal, precision: 9, scale: 3
    add_column :answers, :accuracy, :decimal, precision: 9, scale: 3
  end
end
