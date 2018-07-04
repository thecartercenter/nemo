# frozen_string_literal: true

require "rails_helper"

describe Answer do
  describe "#media_object_id=" do
    context "with existing media object" do
      let(:object) { create(:media_image) }
      let(:answer) { Answer.new(media_object_id: object.id) }

      it "should find and associate with media object" do
        expect(answer.media_object).to eq object
        expect(answer.media_object_id).to eq object.id
      end
    end

    it "should fail silently if object not found" do
      answer = Answer.new(media_object_id: 123)
      expect(answer.media_object).to be_nil
      expect(answer.media_object_id).to be_nil
    end
  end

  describe "validations" do
    describe "date" do
      let(:no_date_ans) { build(:answer, date_value: nil) }
      let(:right_date_ans) { build(:answer, date_value: "2018-01-01") }
      let(:junk_date_ans_str) { build(:answer, date_value: "dog pants") }
      let(:junk_date_ans_int) { build(:answer, date_value: 5) }

      it "answer with no date" do
        expect(no_date_ans).to be_valid
      end

      it "answer with valid date" do
        expect(right_date_ans).to be_valid
      end

      it "answer with invalid string for date" do
        expect(junk_date_ans_str).not_to be_valid
        expect(junk_date_ans_str.errors[:date_value].join).to match(/Date is invalid/)
      end

      it "answer with invalid integer for date" do
        expect(junk_date_ans_int).not_to be_valid
        expect(junk_date_ans_int.errors[:date_value].join).to match(/Date is invalid/)
      end
    end

    describe "date time" do
      let(:no_datetime_ans) { build(:answer, datetime_value: nil) }
      let(:right_datetime_ans) { build(:answer, datetime_value: "2018-01-01 12:00") }
      let(:junk_datetime_ans_str) { build(:answer, datetime_value: "dog pants") }
      let(:junk_datetime_ans_int) { build(:answer, datetime_value: 5) }

      it "answer with no datetime" do
        expect(no_datetime_ans).to be_valid
      end

      it "answer with valid datetime" do
        expect(right_datetime_ans).to be_valid
      end

      it "answer with invalid string for datetime" do
        expect(junk_datetime_ans_str).not_to be_valid
        expect(junk_datetime_ans_str.errors[:datetime_value].join).to match(%r{Date/Time is invalid})
      end

      it "answer with invalid integer for datetime" do
        expect(junk_datetime_ans_int).not_to be_valid
        expect(junk_datetime_ans_int.errors[:datetime_value].join).to match(%r{Date/Time is invalid})
      end
    end
  end
end
