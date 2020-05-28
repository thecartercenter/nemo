# frozen_string_literal: true

class PopulateResponseCachedJson < ActiveRecord::Migration[5.2]
  # Disable transaction wrapper so that the update queries will be committed even if we
  # have to fail the transaction part-way through.
  disable_ddl_transaction!

  def up
    responses = Response.where(filters)
    remaining_responses = ENV["FORCE_REDO"] ? responses : responses.where(cached_json: nil)
    cache_responses(remaining_responses)
  end

  def filters
    if ENV["SUBSET"]
      {
        mission_id: %w[].map do |compact_name|
          Mission.find_by(compact_name: compact_name).id
        end,
        form_id: Form.live.map do |form|
          form.id if form.name.match?(/.*/i)
        end.compact
      }
    else
      {}
    end
  end

  def cache_responses(responses)
    # Disable logging for this db-heavy migration.
    old_level = ActiveRecord::Base.logger.level
    ActiveRecord::Base.logger.level = 1

    total = responses.count
    curr = 0
    responses.find_each do |response|
      json = Results::ResponseJsonGenerator.new(response).as_json
      puts "Updating #{response.shortcode}... (#{curr += 1} / #{total})"
      response.update!(cached_json: json)
    end

    ActiveRecord::Base.logger.level = old_level
  end
end
