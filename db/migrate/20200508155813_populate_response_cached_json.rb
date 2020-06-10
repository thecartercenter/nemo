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

  # By default with no ENV flags, migrate nothing so the deploy is faster.
  def filters
    if ENV["MIGRATE_ALL"]
      {}
    else
      {
        mission_id: (ENV["MISSIONS"] || "").split.map do |compact_name|
          Mission.find_by(compact_name: compact_name).id
        end,
        form_id: Form.live.map do |form|
          form.id if form.name.match?(/.*/i)
        end.compact
      }
    end
  end

  def cache_responses(responses)
    # Disable logging for this db-heavy migration.
    old_level = ActiveRecord::Base.logger.level
    ActiveRecord::Base.logger.level = 1

    total = responses.count
    curr = 0
    responses.find_each do |response|
      puts "Updating #{response.shortcode}... (#{curr += 1} / #{total})"
      json = Results::ResponseJsonGenerator.new(response).as_json
      response.update!(cached_json: json)
    end

    ActiveRecord::Base.logger.level = old_level
  end
end
