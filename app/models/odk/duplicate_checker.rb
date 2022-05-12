# frozen_string_literal: true

module ODK
  # Checks if there is a duplicate odk xml and any attachments
  # Works with multiple attachments
  class DuplicateChecker
    attr_accessor :files, :user_id

    def initialize(files, user)
      @files = files
      @user = user
    end

    def duplicate?
      existing_xml_blobs = find_blobs(@files[:xml_submission_file])
      return false unless dupe_response_and_user?(existing_xml_blobs)

      # If multi part submission, check other attachments
      other_files = @files.except(:xml_submission_file)
      return true if other_files.blank?

      other_files.all? do |f|
        dupe_response_and_user?(find_blobs(f[1]))
      end
    end

    private

    def find_blobs(file)
      checksum = compute_checksum_in_chunks(File.new(file))
      ActiveStorage::Blob.where(checksum: checksum)
    end

    def dupe_response_and_user?(blobs)
      blobs.each do |blob|
        attachment = ActiveStorage::Attachment.find_by(blob_id: blob.id)
        next if attachment.nil?
        response = Response.find_by(id: attachment.record_id)
        return true if response.present? && response.user.id == @user.id
      end
      false
    end

    # ActiveStorage checksum; copied from Rails to be identical:
    # https://github.com/rails/rails/blob/main@{2022-04-01}/activestorage/app/models/active_storage/blob.rb#L369
    #
    # rubocop:disable Naming/MethodParameterName, Lint/AssignmentInCondition
    def compute_checksum_in_chunks(io)
      OpenSSL::Digest.new("MD5").tap do |checksum|
        while chunk = io.read(5.megabytes)
          checksum << chunk
        end
        io.rewind
      end.base64digest
    end
    # rubocop:enable Naming/MethodParameterName, Lint/AssignmentInCondition
  end
end
