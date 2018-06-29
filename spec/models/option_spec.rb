# frozen_string_literal: true

require "rails_helper"

describe Option do
  it "should create cleanly" do
    create(:option, name: "Foo")
  end

  describe "normalization" do
    let(:option) { build(:option, submitted) }
    subject { submitted.keys.map { |k| [k, option.send(k)] }.to_h }

    before { option.valid? } # Trigger normalization.

    describe "value" do
      context "integer" do
        let(:submitted) { {value: 123} }
        it { is_expected.to eq(value: 123) }
      end

      context "integer string" do
        let(:submitted) { {value: "123"} }
        it { is_expected.to eq(value: 123) }

        context "leading and trailing whitespace" do
          let(:submitted) { {value: "\t  123  \n"} }
          it { is_expected.to eq(value: 123) }
        end
      end

      context "blank string" do
        let(:submitted) { {value: "   \t\n"} }
        it { is_expected.to eq(value: nil) }
      end

      context "non-numeric string" do
        let(:submitted) { {value: "  notanumber123  "} }
        it { is_expected.to eq(value: 0) } # Rails does this automatically
      end
    end
  end

  context "with coordinates" do
    it "should require both latitude and longitude if either are present" do
      # check each field with the other missing
      %i[latitude longitude].each do |field|
        option = build(:option, field => 0)
        expect(option).to be_invalid
      end

      # check with the both present
      option = create(:option, latitude: 0, longitude: 0)
      expect(option).to be_valid
    end

    it "should reject out-of-range latitudes" do
      [-100, 100].each do |value|
        option = build(:option, latitude: value, longitude: 0)
        expect(option).to be_invalid
      end
    end

    it "should reject out-of-range longitudes" do
      [-200, 200].each do |value|
        option = build(:option, latitude: 0, longitude: value)
        expect(option).to be_invalid
      end
    end
  end

  context "has_coordinates?" do
    it "should return true if there are full coordinates" do
      option = build(:option, latitude: 0, longitude: 0)
      expect(option.has_coordinates?).to be_truthy
    end

    it "should return true if there are partial coordinates" do
      option = build(:option, latitude: 0)
      expect(option.has_coordinates?).to be_truthy
    end

    it "should return false if there are no coordinates" do
      option = build(:option)
      expect(option.has_coordinates?).to be_falsy
    end
  end
end
