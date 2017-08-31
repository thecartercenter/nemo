require "spec_helper"

describe Answer do
  describe "lat/lng validation" do
    let(:form) { create(:form, question_types: ["location"]) }
    let(:qing) { form.sorted_children[0] }
    let(:answer) { build(:answer, questioning: qing, value: value) }

    context "with normal values" do
      let(:value) { "-2.366030 -0.039825" }

      it { expect(answer.save).to be true }
    end

    context "with normal values but extra precision" do
      let(:value) { "-2.3660309999 -0.0398259999" }

      it do
        expect(answer.save).to be true
        expect(answer.value).to eq "-2.366031 -0.039826"
      end
    end

    context "with invalid latitude" do
      let(:value) { "-92.366030 -0.039825" }

      it do
        expect(answer).not_to be_valid
        expect(answer.errors[:value].join).to match /Latitude is out of range/
      end
    end

    context "with invalid longitude" do
      let(:value) { "-4.366030 -181.039825" }

      it do
        expect(answer).not_to be_valid
        expect(answer.errors[:value].join).to match /Longitude is out of range/
      end
    end

    context "with hugely invalid latitude" do
      let(:value) { "-4000000000000000.366030 -29.039825" }

      it do
        expect(answer).not_to be_valid
        expect(answer.errors[:value].join).to match /Latitude is out of range/
      end
    end
  end
end
