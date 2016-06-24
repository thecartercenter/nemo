class CreateFormForwardings < ActiveRecord::Migration
  def change
    create_table :form_forwardings do |t|
      t.references :form, index: true, foreign_key: true
      t.references :forwardee, index: true, polymorphic: true

      t.timestamps null: false
    end
  end
end
