require "spec_helper"

describe "geopoint processing" do
  let(:form) { create(:form, question_types: %w(location)) }
  let(:questioning) { form.questionings.first }
  let(:answer) { build(:answer, questioning: questioning, value: value) }

  context "with no value" do
    let(:value) { "" }

    it "should process properly" do
      expect_location_answer(val: nil, lat: nil, lng: nil, alt: nil, acc: nil)
    end

    it "should be valid" do
      expect(answer).to be_valid
    end
  end

  context "with normal lat/lng values" do
    let(:value) { "-2.366030 -0.039825" }

    it "should process properly" do
      expect_location_answer(val: value, lat: -2.366030, lng: -0.039825, alt: nil, acc: nil)
    end

    it "should be valid" do
      expect(answer).to be_valid
    end
  end

  context "with normal lat/lng/alt values" do
    let(:value) { "-2.366030 -0.039825 100.235" }

    it "should process properly" do
      expect_location(val: value, lat: -2.366030, lng: -0.039825, alt: 100.235, acc: nil)
    end

    it "should be valid" do
      expect(answer).to be_valid
    end
  end

  context "with normal lat/lng/alt/acc values" do
    let(:value) { "-2.366030 -0.039825 100.235 20.000" }

    it "should process properly" do
      expect_location_answer(val: value, lat: -2.366030, lng: -0.039825, alt: 100.235, acc: 20.0)
    end

    it "should be valid" do
      expect(answer).to be_valid
    end
  end

  context "with normal values but extra precision" do
    let(:value) { "-2.3660309999 -0.0398259999 100.2350001 20.00001" }

    it "should process properly" do
      expect_location_answer(val: "-2.366031 -0.039826 100.235 20.000",
        lat: -2.366030, lng: -0.039825, alt: 100.235, acc: 20.0)
    end

    it "should be valid" do
      expect(answer).to be_valid
    end
  end

  context "with invalid latitude" do
    let(:value) { "-92.366030 -0.039825" }

    it "should process properly" do
      expect_location_answer(val: value, lat: -92.366030, lng: -0.039825, alt: nil, acc: nil)
    end

    it "should be invalid" do
      expect(answer).not_to be_valid
      expect(answer.errors[:value].join).to match /Latitude is out of range/
    end
  end

  context "with hugely invalid latitude" do
    let(:value) { "-4000000000000000.366030 -29.039825" }

    it "should process properly" do
      expect_location_answer(val: "0.000000 -29.039825", lat: 0, lng: -29.039825, alt: nil, acc: nil)
    end

    it "should be invalid" do
      expect(answer).not_to be_valid
      expect(answer.errors[:value].join).to match /Latitude is out of range/
    end
  end

  context "with invalid longitude" do
    let(:value) { "-4.366030 -181.039825" }

    it "should process properly" do
      expect_location_answer(val: value, lat: -4.366030, lng: -181.039825, alt: nil, acc: nil)
    end

    it "should be invalid" do
      expect(answer).not_to be_valid
      expect(answer.errors[:value].join).to match /Longitude is out of range/
    end
  end

  context "with missing longitude" do
    let(:value) { "-4.366030" }

    it "should process properly" do
      expect_location_answer(val: value, lat: -4.366030, lng: nil, alt: nil, acc: nil)
    end

    it "should be invalid" do
      expect(answer).not_to be_valid
      expect(answer.errors[:value].join).to match /Longitude is out of range/
    end
  end

  context "with invalid altitude" do
    let(:value) { "-4.366030 -22.039825 1000009.9" }

    it "should process properly" do
      expect_location_answer(val: "-4.366030 -22.039825 0.000",
        lat: -4.366030, lng: -22.039825, alt: 0.0, acc: nil)
    end

    it "should be invalid" do
      expect(answer).not_to be_valid
      expect(answer.errors[:value].join).to match /Altitude is out of range/
    end
  end

  context "with negative accuracy" do
    let(:value) { "-4.366030 -22.039825 33.9 -1.0" }

    it "should process properly" do
      expect_location_answer(val: "-4.366030 -22.039825 33.900 0.000",
        lat: -4.366030, lng: -22.039825, alt: 33.9, acc: 0.0)
    end

    it "should be invalid" do
      expect(answer).not_to be_valid
      expect(answer.errors[:value].join).to match /Accuracy can't be negative/
    end
  end

  context "with too large accuracy" do
    let(:value) { "-4.366030 -22.039825 33.9 1000007.5" }

    it "should process properly" do
      expect_location_answer(val: "-4.366030 -22.039825 33.900 0.000",
        lat: -4.366030, lng: -22.039825, alt: 33.9, acc: 0.0)
    end

    it "should be invalid" do
      expect(answer).not_to be_valid
      expect(answer.errors[:value].join).to match /Accuracy is out of range/
    end
  end

  context "with extra value" do
    let(:value) { "-2.366030 -0.039825 100.235 20.000 35.2" }

    it "should process properly" do
      expect_location_answer(val: "-2.366030 -0.039825 100.235 20.000",
        lat: -2.366030, lng: -0.039825, alt: 100.235, acc: 20.0)
    end

    it "should be valid" do
      expect(answer).to be_valid
    end
  end
end
