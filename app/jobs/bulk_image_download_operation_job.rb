# frozen_string_literal: true

# Operation for exporting all media on a form.
class BulkImageDownloadOperationJob < OperationJob
  def perform(operation, search: nil, options: {})
    ability = Ability.new(user: operation.creator, mission: mission)
    packager = Utils::BulkMediaPackager.new(ability: ability, search: search, operation: operation)

    if packager.space_on_disk?
      result = packager.download_and_zip_images
      attachment = Tempfile.open(result.to_s)
      save_attachment(attachment, result.basename)
    else
      raise "Not enough space on disk for media export"
    end
  rescue Search::ParseError => e
    operation_failed(e.to_s)
  end
end
