# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: options
#
#  id                :uuid             not null, primary key
#  canonical_name    :string(255)      not null
#  latitude          :decimal(8, 6)
#  longitude         :decimal(9, 6)
#  name_translations :jsonb            not null
#  value             :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  mission_id        :uuid
#
# Indexes
#
#  index_options_on_canonical_name     (canonical_name)
#  index_options_on_mission_id         (mission_id)
#  index_options_on_name_translations  (name_translations) USING gin
#
# Foreign Keys
#
#  options_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe Option do
  it "should create cleanly" do
    create(:option, name: "Foo")
  end

  describe "normalization" do
    let(:option) { build(:option, submitted) }
    subject { submitted.keys.index_with { |k| option.send(k) }.to_h }

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

  describe "#coordinates=" do
    let(:option) { create(:option, coordinates: str) }
    subject(:coordinates) { option.coordinates }

    context do
      let(:str) { "12.3,4.56" }
      it { is_expected.to eq("12.3, 4.56") }
    end

    context do
      let(:str) { "-12.3 :  4.56" }
      it { is_expected.to eq("-12.3, 4.56") }
    end

    context do
      let(:str) { "-12.33875295723;-4.56294385279484" }
      it { is_expected.to eq("-12.338752, -4.562943") }
    end

    context do
      let(:str) { "12 4" }
      it { is_expected.to eq("12.0, 4.0") }
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

  context "coordinates?" do
    it "should return true if there are full coordinates" do
      option = build(:option, latitude: 0, longitude: 0)
      expect(option.coordinates?).to be(true)
    end

    it "should return true if there are partial coordinates" do
      option = build(:option, latitude: 0)
      expect(option.coordinates?).to be(true)
    end

    it "should return false if there are no coordinates" do
      option = build(:option)
      expect(option.coordinates?).to be(false)
    end
  end
end
