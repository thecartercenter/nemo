class AddCachedJsonToResponse < ActiveRecord::Migration[5.2]
  def change
    add_column :responses, :cached_json, :jsonb

    reversible do |dir|
      dir.up do
        cache_responses
      end
    end
  end

  def cache_responses
    # TODO: Temporary filter
    # haitimalaria riverblindnessnigeria2017
    mission_ids = ["sandbox"].map do |compact_name|
      Mission.find_by(compact_name: compact_name).id
    end
    limited_responses = Response.where(mission_id: mission_ids)

    total = limited_responses.count
    curr = 0
    limited_responses.find_each do |response|
      json = Results::ResponseJsonGenerator.new(response).as_json
      puts "Updating #{response.shortcode}... (#{curr += 1} / #{total})"
      response.update!(cached_json: json)
    end
  end
end
