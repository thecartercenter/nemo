# frozen_string_literal: true

require "azure/storage/blob"
require "json"
require "set"

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
    fields: {
      entityType: "mission",
      missionId: :id,
    }
  }.merge(GENERIC_METADATA),
  User: {
    fields: {
      entityType: "user",
      userId: :id,
      login: :login,
    }
  }.merge(GENERIC_METADATA),
  Assignment: {
    fields: {
      entityType: "mission-user assignment",
      assignmentId: :id,
      missionId: :mission_id,
      userId: :user_id,
      role: :role,
    }
  }.merge(GENERIC_METADATA),
  Form: {
    fields: {
      entityType: "form",
      formId: :id,
      missionId: :mission_id,
    }
  }.merge(GENERIC_METADATA),
  MediaPrompt: {
    resolver: ->(id) { Question.find(id) },
    fields: {
      entityType: "media prompt hint",
      mediaPromptId: ->(question) { "#{question.id}_media_prompt" },
      questionCode: :code,
      # This can cause the tags field to be far too long.
      # formIds: ->(question) { question.form_ids.join(",") },
      missionId: :mission_id,
    }
  }.merge(GENERIC_METADATA),
  Response: {
    fields: {
      entityType: "response",
      responseId: :id,
      formId: :form_id,
      userId: :user_id,
      missionId: :mission_id,
    }
  }.merge(GENERIC_METADATA),
  ResponseAttachment: {
    resolver: ->(id) { Response.find(id) },
    fields: {
      entityType: "response attachment",
      responseId: :id,
      formId: :form_id,
      userId: :user_id,
      missionId: :mission_id,
    }
  }.merge(GENERIC_METADATA),
}.freeze

def metadata_for(klass, id)
  metadata = METADATA[klass.to_sym] || {}

  # Given "Form, 123" find the Form with ID 123
  resolver = metadata[:resolver]
  item = resolver.present? ? resolver.call(id) : klass.constantize.find(id)

  # Transform each placeholder value in the metadata (such as :form_id)
  # into the actual value from the item (such as "123-456").
  metadata[:fields].transform_values do |v|
    value = case v
            when Symbol
              # Call the method named :v
              item.public_send(v)
            when Proc
              # Call the procedure we were provided
              v.call(item)
            else
              # Return a literal value
              v
            end
    value.nil? ? "null" : value.to_s
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

  # Track which files have been uploaded already in case we need to re-run.
  manifest_path = File.join(directory, ".upload_manifest.json")
  processed = if File.exist?(manifest_path)
                JSON.parse(File.read(manifest_path)).to_set
              else
                Set.new
              end

  puts "Directory: #{directory}"
  Dir.glob("#{directory}/*.*").sort.each do |file|
    filename = File.basename(file)
    next if filename == File.basename(manifest_path) # Don't upload the manifest itself.

    if processed.include?(filename)
      puts "Skipping #{filename}..."
      next
    end

    # Extract tokens from space-separated filename.
    classname, id = filename.split(".").first.split

    # Upload each file with tag metadata.
    puts "Uploading #{classname} #{id}..."

    File.open(file, "rb") do |f|
      metadata = metadata_for(classname, id)
      # TODO: Submit PR for fork
      result = client.create_block_blob(CONTAINER_NAME, filename, f, {tags: metadata.to_query})
      puts result.properties[:last_modified]
    end

    # Mark as processed after successful upload.
    processed << filename
    File.write(manifest_path, JSON.pretty_generate(processed.to_a.sort))
  end
end
