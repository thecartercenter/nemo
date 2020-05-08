# frozen_string_literal: true

class PopulateResponseCachedJson < ActiveRecord::Migration[5.2]
  # Disable transaction wrapper so that the update queries will be committed even if we
  # have to fail the transaction part-way through.
  disable_ddl_transaction!

  def up
    # TODO: Temporary filter; sandbox haitimalaria riverblindnessnigeria2017
    mission_ids = %w[sandbox haitimalaria riverblindnessnigeria2017].map do |compact_name|
      Mission.find_by(compact_name: compact_name).id
    end
    # form_ids = Form.live.distinct(:id).pluck(:id)
    form_ids = Form.live.distinct(:id).map do |form|
      form.id if form.name.match?(/CDDAtt/i)
    end.compact
    responses = Response.where(mission_id: mission_ids, form_id: form_ids)
    remaining_responses = ENV["FORCE_REDO"] ? responses : responses.where(cached_json: nil)

    cache_responses(remaining_responses)
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
