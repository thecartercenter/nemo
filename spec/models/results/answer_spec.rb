# frozen_string_literal: true

require "rails_helper"

describe Answer do
  describe "#media_object_id=" do
    context "with existing media object" do
      let(:object) { create(:media_image) }
      let(:answer) { Answer.new(media_object_id: object.id) }

      it "should find and associate with media object" do
        expect(answer.media_object).to eq(object)
        expect(answer.media_object_id).to eq(object.id)
      end
    end

    it "should fail silently if object not found" do
      answer = Answer.new(media_object_id: 123)
      expect(answer.media_object).to be_nil
      expect(answer.media_object_id).to be_nil
    end
  end

  describe "validations" do
    # We need to build the Answer using `new` instead of the factory because the factory chokes
    # on multiparam attribs like "date_value(1i)".
    subject(:answer) { Answer.new(build(:answer).attributes.merge(attribs)) }

    shared_examples_for "invalid" do
      it do
        expect(answer).not_to be_valid
        expect(answer.errors[attrib].join).to match(/is invalid/)
        expect(answer[attrib]).to be_nil
      end
    end

    describe "date" do
      let(:attrib) { :date_value }

      context "with no date" do
        let(:attribs) { {date_value: nil} }
        it { is_expected.to be_valid }
      end

      context "with valid date" do
        let(:attribs) { {date_value: "2018-01-01"} }
        it { is_expected.to be_valid }
      end

      context "with valid date via multiparam attribs" do
        let(:attribs) { {"date_value(1i)" => "1985", "date_value(2i)" => "4", "date_value(3i)" => "3"} }
        it { is_expected.to be_valid }
      end

      context "with off by one date via multiparam attribs" do
        let(:attribs) { {"date_value(1i)" => "1985", "date_value(2i)" => "4", "date_value(3i)" => "31"} }
        it do
          expect(answer).to be_valid
          expect(answer.date_value.strftime("%Y%m%d")).to eq("19850501")
        end
      end

      context "with formatted but invalid date string" do
        let(:attribs) { {date_value: "2018-01-90"} }
        it_behaves_like("invalid")
      end

      context "with totally invalid date string" do
        let(:attribs) { {date_value: "dog pants"} }
        it_behaves_like("invalid")
      end

      # This one errors and is not handled, but that's ok because the select boxes shouldn't let it happen.
      context "with invalid date via multiparam attribs" do
        let(:attribs) { {"date_value(1i)" => "1985", "date_value(2i)" => "4", "date_value(3i)" => "32"} }
        it { expect { answer }.to raise_error(ActiveRecord::MultiparameterAssignmentErrors) }
      end
    end

    describe "datetime" do
      let(:attrib) { :datetime_value }

      context "with no datetime" do
        let(:attribs) { {datetime_value: nil} }
        it { is_expected.to be_valid }
      end

      context "with valid datetime" do
        let(:attribs) { {datetime_value: "1985-04-03 10:15:55"} }
        it { is_expected.to be_valid }
      end

      context "with valid datetime via multiparam attribs" do
        let(:attribs) do
          {
            "datetime_value(1i)" => "1985",
            "datetime_value(2i)" => "4",
            "datetime_value(3i)" => "3",
            "datetime_value(4i)" => "12",
            "datetime_value(5i)" => "9",
            "datetime_value(6i)" => "1"
          }
        end
        it { is_expected.to be_valid }
      end

      context "with day-off-by-one datetime via multiparam attribs" do
        let(:attribs) do
          {
            "datetime_value(1i)" => "1985",
            "datetime_value(2i)" => "4",
            "datetime_value(3i)" => "31",
            "datetime_value(4i)" => "10",
            "datetime_value(5i)" => "10",
            "datetime_value(6i)" => "10"
          }
        end
        it do
          expect(answer).to be_valid
          expect(answer.datetime_value.strftime("%Y%m%d%H%M%S")).to eq("19850501101010")
        end
      end

      context "with formatted but invalid datetime string" do
        let(:attribs) { {datetime_value: "2018-01-90 10:90:22"} }
        it_behaves_like("invalid")
      end

      context "with totally invalid datetime string" do
        let(:attribs) { {datetime_value: "dog pants"} }
        it_behaves_like("invalid")
      end

      # This one errors and is not handled, but that's ok because the select boxes shouldn't let it happen.
      context "with invalid datetime via multiparam attribs" do
        let(:attribs) do
          {
            "datetime_value(1i)" => "1985",
            "datetime_value(2i)" => "4",
            "datetime_value(3i)" => "30",
            "datetime_value(4i)" => "25",
            "datetime_value(5i)" => "10",
            "datetime_value(6i)" => "10"
          }
        end
        it { expect { answer }.to raise_error(ActiveRecord::MultiparameterAssignmentErrors) }
      end
    end
  end
end
