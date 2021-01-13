# frozen_string_literal: true

shared_context "media helpers" do
  shared_examples "accepts file types" do |file_types|
    file_types.each do |type|
      context "with #{type} file" do
        let(:media_file) { build(factory_name(described_class), fixture: file_for_type(type)) }

        it "is valid" do
          expect(media_file).to be_valid
        end
      end
    end
  end

  shared_examples "rejects file types" do |file_types|
    file_types.each do |type|
      context "with #{type} file" do
        let(:media_file) { build(factory_name(described_class), fixture: file_for_type(type)) }

        it "is invalid" do
          expect(media_file).to have(1).error_on(:item)
          expect(media_file).to be_invalid
        end
      end
    end
  end

  def factory_name(described_class)
    described_class.name.underscore.tr("/", "_").to_sym
  end

  def file_for_type(file_type)
    case file_type
    when "audio"
      media_fixture("audio/powerup.mp3")
    when "image"
      media_fixture("images/the_swing.jpg")
    when "video"
      media_fixture("video/jupiter.mp4")
    end
  end
end
