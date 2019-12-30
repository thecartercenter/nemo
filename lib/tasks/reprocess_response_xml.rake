# frozen_string_literal: true

# Reprocesses ALL response XML. May overwrite data and will cause
# incorrect create/update stamps for answers.
# WARNING: Does not work properly with media objects.
task reprocess_response_xml: :environment do
  Response.where.not(odk_xml: nil).find_each do |response|
    puts "Response #{response.id}"
    response.answers.each(&:destroy_fully!)
    XMLSubmission.new(response: response.reload, files: [], source: "odk", data: response.odk_xml).save
  end
end
