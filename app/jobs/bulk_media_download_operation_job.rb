# frozen_string_literal: true

require "fileutils"

# Operation for exporting all media on a form.
class BulkMediaDownloadOperationJob < OperationJob
  def perform(operation, search: nil, options: {})
    ability = Ability.new(user: operation.creator, mission: mission)
    packager = Utils::BulkMediaPackager.new(
      ability: ability, search: search, selected: options[:selected], operation: operation
    )

    raise "Not enough space on disk for media export" unless packager.space_on_disk?

    result = packager.download_and_zip_images
    save_attachment(File.open(result.to_s), result.basename)
    FileUtils.remove_file(result)
  rescue Search::ParseError => e
    operation_failed(e.to_s)
  end
end
