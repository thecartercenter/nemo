require "spec_helper"

describe Option do
  it "should create cleanly" do
    create(:option, name: "Foo")
  end

  describe "normalization" do
    let(:option) { create(:option) }

    describe "value" do
      subject { option.value }

      context "integer" do
        before { option.value = 123 }
        it { expect(subject).to eq 123 }
      end

      context "integer string" do
        before { option.value = "123" }
        it { expect(subject).to eq 123 }

        context "leading and trailing whitespace" do
          before { option.value = "\t  123  \n" }
          it { expect(subject).to eq 123 }
        end
      end

      context "blank string" do
        before { option.value = "   \t\n" }
        it { expect(subject).to eq nil }
      end
    end
  end

  describe "validations" do
    subject { create(:option) }

    context "with value" do
      before { subject.value = 123 }

      it "validates numericality of value" do
        subject.value = "abc"
        expect(subject).to_not be_valid
      end
    end
  end

  context "with coordinates" do
    it "should require both latitude and longitude if either are present" do
      # check each field with the other missing
      %i(latitude longitude).each do |field|
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
