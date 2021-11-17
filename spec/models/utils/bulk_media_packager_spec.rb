# frozen_string_literal: true

require "rails_helper"
require "fileutils"
require "zip"

describe Utils::BulkMediaPackager do
  context "happy paths" do
    let(:user) { create(:user, role_name: "coordinator") }
    let(:operation) { create(:operation, creator: user) }
    let!(:form) { create(:form, name: "foo", question_types: %w[image]) }
    let!(:form2) { create(:form, name: "bar", question_types: %w[image]) }

    let(:media_jpg) { create(:media_image, :jpg) }
    let(:media_png) { create(:media_image, :png) }
    let(:media_tiff) { create(:media_image, :tiff) }

    let!(:responses) do
      [
        create(:response, form: form, answer_values: [media_jpg]),
        create(:response, form: form, answer_values: [media_png]),
        create(:response, form: form2, answer_values: [media_tiff])
      ]
    end

    describe "bulk image packager" do
      it "should return the correct size of images" do
        ability = Ability.new(user: operation.creator, mission: operation.mission)
        packager = described_class.new(
          ability: ability, search: nil, selected: [], operation: operation
        )
        size = packager.download_size
        expect(size).to equal(1_819_435)
      end

      it "should return the correct size of images with search" do
        ability = Ability.new(user: operation.creator, mission: operation.mission)
        packager = described_class.new(
          ability: ability, search: "form: foo", selected: [], operation: operation
        )
        size = packager.download_size
        expect(size).to equal(855_939)
      end

      it "should return the correct size of images with checkbox selection" do
        ability = Ability.new(user: operation.creator, mission: operation.mission)
        packager = described_class.new(
          ability: ability, search: "form: foo", selected: [responses.first.id], operation: operation
        )
        size = packager.download_size
        expect(size).to equal(106_886)
      end

      it "should download, zip all the images, and cleanup" do
        ability = Ability.new(user: operation.creator, mission: operation.mission)
        packager = described_class.new(
          ability: ability, search: "form: foo", selected: [], operation: operation
        )
        results = packager.download_and_zip_images

        expect(results.basename.to_s).to match(/#{operation.mission.compact_name}-media-.+.zip/)
        expect(File.exist?(results.to_s)).to be(true)
        expect(Dir["#{results.dirname}/*.jpg"].any?).to be(false)

        Zip::File.open(results.to_s) do |zipfile|
          expect(zipfile.count).to be(2)
          zipfile.each do |file|
            expect(file.name).to match(/nemo-.+-.+.(jpg|png|tiff)/)
          end
        end
      end

      it "should only zip the selection" do
        ability = Ability.new(user: operation.creator, mission: operation.mission)
        packager = described_class.new(
          ability: ability, search: "form: foo", selected: [responses.first.id], operation: operation
        )
        results = packager.download_and_zip_images

        Zip::File.open(results.to_s) do |zipfile|
          expect(zipfile.count).to be(1)
        end
      end
    end
  end
end
