class AddMissionIdToModels < ActiveRecord::Migration[4.2]
  def change
    tables = [:responses, :forms, :report_reports, :options, :option_sets, :questions, :form_types, :broadcasts, :languages, :settings]

    # find default mission or quit
    #(mission = Mission.find_by_name("Default")) || raise("Couldn't find default mission.")

    # add mission_id columns, update all to default mission_id, then add index
    tables.each do |t|
      # add column
      add_column(t, :mission_id, :integer)

      # add index
      add_index(t, [:mission_id])
    end
  end
end
