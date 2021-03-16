# frozen_string_literal: true

require "rails_helper"

describe BulkMediaDownloadOperationJob do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:operation) { create(:operation, creator: user) }
  let!(:form) { create(:form, name: "foo", question_types: %w[image]) }
  let!(:form2) { create(:form, name: "bar", question_types: %w[image]) }

  let(:media_jpg) { create(:media_image, :jpg) }
  let(:media_png) { create(:media_image, :png) }
  let(:media_tiff) { create(:media_image, :tiff) }

  let(:zip) { operation.attachment.download }
  let!(:responses) do
    [
      create(:response, form: form, answer_values: [media_jpg]),
      create(:response, form: form, answer_values: [media_png]),
      create(:response, form: form2, answer_values: [media_tiff])
    ]
  end

  describe "#perform" do
    it "succeeds" do
      described_class.perform_now(operation)
      expect(:zip).not_to be_nil
    end
  end
end
