# frozen_string_literal: true

require "azure/storage/blob"

CONTAINER_NAME = "local-test"

task :azure_upload do
  directory = Rails.root.join("tmp/archives/upload")

  client = Azure::Storage::Blob::BlobService.create(
    storage_account_name: ENV.fetch("NEMO_AZURE_STORAGE_ACCOUNT_NAME", nil),
    storage_access_key: ENV.fetch("NEMO_AZURE_STORAGE_ACCESS_KEY", nil)
  )

  # Add retry filter to the service object
  # require "azure/storage/common"
  # client.with_filter(Azure::Storage::Common::Core::Filter::ExponentialRetryPolicyFilter.new)

  # container = client.list_containers.first # local-test
  # puts "Container found: " + container.name

  Dir.glob("#{directory}/*.csv") do |file|
    # Extract tokens from space-separated filename.
    filename = File.basename(file)
    classname, id = filename.split(".csv").first.split

    # Read each CSV and upload it with tag metadata.
    CSV.foreach(file, headers: true) do |row|
      # login = row['login']
      puts "Uploading #{classname} #{id}..."

      # az storage blob upload --account-name testnemo2026 --container-name local-test --tags entityType="mission" missionId="123" --overwrite --file mission-123.csv
      # exec("az storage blob upload --account-name testnemo2026 --container-name local-test --tags login=\"#{login}\" --overwrite --file \"#{file}\"")
      File.open(file, "rb") do |f|
        client.create_block_blob(CONTAINER_NAME, filename, f)
      end
    end
  end
end
