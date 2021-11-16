# frozen_string_literal: true

require "fileutils"

# Operation for exporting original ODK XML files.
class XmlDownloadOperationJob < OperationJob
  def perform(operation, search: nil, options: {})
    ability = Ability.new(user: operation.creator, mission: mission)

    packager = Utils::XmlPackager.new(
      ability: ability, search: search, selected: options[:selected], operation: operation
    )

    raise "Not enough space on disk for XML export" unless packager.space_on_disk?

    result = packager.download_and_zip_xml
    save_attachment(File.open(result.to_s), result.basename)
    FileUtils.remove_file(result)
  rescue Search::ParseError => e
    operation_failed(e.to_s)
  end
end
