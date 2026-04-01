# frozen_string_literal: true

require "azure/storage/blob"

CONTAINER_NAME = "local-test"
AZURE_NAME = ENV.fetch("NEMO_AZURE_STORAGE_ACCOUNT_NAME", nil)
AZURE_KEY = ENV.fetch("NEMO_AZURE_STORAGE_ACCESS_KEY", nil)

GENERIC_METADATA = {
  createdAt: :created_at,
  updatedAt: :updated_at,
  schemaVersion: "1"
}.freeze

METADATA = {
  Mission: {
    entityType: "mission",
    missionId: :id,
  }.merge(GENERIC_METADATA),
  User: {
    entityType: "user",
    userId: :id,
    login: :login,
    # missionId: ->(item) { item.mission_id }, # TODO: export dupe users across missions
    # role: ->(item) { item.role(item.mission_id) }, # TODO: allow this
  }.merge(GENERIC_METADATA),
}.freeze

def metadata_for(klass, id)
  item = klass.constantize.find(id)
  metadata = METADATA[klass.to_sym] || {}

  metadata.transform_values do |v|
    case v
    when Symbol
      item.public_send(v)
    when Proc
      v.call(item)
    else
      v
    end
  end
end

task azure_upload: :environment do
  directory = Rails.root.join("tmp/archives/upload")

  client = Azure::Storage::Blob::BlobService.create(
    storage_account_name: AZURE_NAME,
    storage_access_key: AZURE_KEY
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
    # Each CSV should only have 1 row.
    CSV.foreach(file, headers: true) do |row|
      # login = row["login"]
      puts "Uploading #{classname} #{id}..."

      File.open(file, "rb") do |f|
        metadata = metadata_for(classname, id)
        result = client.create_block_blob(CONTAINER_NAME, filename, f, {tags: metadata.to_query})
        puts result.properties[:last_modified]
      end
    end
  end
end
