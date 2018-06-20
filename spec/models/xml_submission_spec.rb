# frozen_string_literal: true

require "spec_helper"

describe XMLSubmission, :odk do
  include_context "odk submissions"

  let(:xml) { build_odk_submission(form, data: data) }
  let(:files) { {xml_submission_file: StringIO.new(xml)} }
  let(:response) { Response.new(form: form, mission: form.mission, user: create(:user)) }

  #let(:submission) { XMLSubmission.new(response: response, files: files) }

  let(:nodes) { AnswerArranger.new(response).build.nodes }

  before do
    form.publish!
    Odk::ResponseParser.new(response: response, files: files).populate_response
    response.save(validate: false)
  end

  context "with a repeat group and instances" do
    let(:form) { create(:form, question_types: ["integer", %w[integer integer]]) }
    let(:data) do
      {
        form.c[0] => "123",
        form.c[1] => [
          {
            form.c[1].c[0] => "456",
            form.c[1].c[1] => "789"
          }, {
            form.c[1].c[1] => "34"
          }, {
            form.c[1].c[0] => "56",
            form.c[1].c[1] => "78"
          }
        ]
      }
    end

    it "processes repeats correctly" do
      expect(nodes.size).to eq 2
      expect(nodes[0].set.answers[0].value).to eq "123"
      expect(nodes[0].set.answers[0].rank).to eq 1

      expect(nodes[1].instances.size).to eq 3
      expect(nodes[1].instances[0].nodes[0].set.answers[0].value).to eq "456"
      expect(nodes[1].instances[0].nodes[1].set.answers[0].value).to eq "789"

      expect(nodes[1].instances[1].nodes[0].set.answers[0].value).to be_nil
      expect(nodes[1].instances[1].nodes[1].set.answers[0].value).to eq "34"

      expect(nodes[1].instances[2].nodes[0].set.answers[0].value).to eq "56"
      expect(nodes[1].instances[2].nodes[1].set.answers[0].value).to eq "78"

      expect(response.odk_xml).to match /<data/
    end
  end

  context "with complex selects" do
    let(:form) do
      create(:form, question_types: %w[select_one multilevel_select_one
                                       select_multiple integer multilevel_select_one])
    end
    let(:cat) { form.c[0].option_set.sorted_children[0] }
    let(:plant) { form.c[1].option_set.sorted_children[0] }
    let(:oak) { form.c[1].option_set.sorted_children[1] }
    let(:cat2) { form.c[2].option_set.sorted_children[0] }
    let(:dog2) { form.c[2].option_set.sorted_children[1] }
    let(:animal) { form.c[4].option_set.sorted_children[0] }
    let(:data) do
      {
        form.c[0] => "on#{cat.id}",
        form.c[1] => ["on#{plant.id}", "on#{oak.id}"],
        form.c[2] => "on#{cat2.id} on#{dog2.id}",
        form.c[3] => "123",
        form.c[4] => ["on#{animal.id}", "none"]
      }
    end

    it "processes correct values" do
      puts xml
      expect(nodes[0].set.answers[0].option).to eq cat.option
      expect(nodes[0].set.answers[0].rank).to eq 1

      expect(nodes[1].set.answers[0].option).to eq plant.option
      expect(nodes[1].set.answers[0].rank).to eq 1
      expect(nodes[1].set.answers[1].option).to eq oak.option
      expect(nodes[1].set.answers[1].rank).to eq 2

      expect(nodes[2].set.answers[0].choices.map(&:option)).to eq [cat2.option, dog2.option]
      expect(nodes[2].set.answers[0].rank).to eq 1

      expect(nodes[3].set.answers[0].value).to eq "123"
      expect(nodes[3].set.answers[0].rank).to eq 1

      expect(nodes[4].set.answers[0].option).to eq animal.option
      expect(nodes[4].set.answers[0].rank).to eq 1
      expect(nodes[4].set.answers[1].option).to be_nil
      expect(nodes[4].set.answers[1].rank).to eq 2
    end
  end

  context "with location type" do
    let(:form) { create(:form, question_types: %w[location]) }
    let(:answer) { nodes[0].set.answers[0] }

    context "with just lat/lng" do
      let(:data) { {form.c[0] => "12.3456 -76.99388"} }

      it "processes correct values" do
        puts xml
        expect_location_answer(answer, val: "12.345600 -76.993880",
                                       lat: 12.3456, lng: -76.99388, alt: nil, acc: nil)
      end
    end

    context "with lat/lng/alt/acc" do
      let(:data) { {form.c[0] => "12.3456 -76.99388 123.456 20.0"} }

      it "processes correct values" do
        expect_location_answer(answer, val: "12.345600 -76.993880 123.456 20.000",
                                       lat: 12.3456, lng: -76.99388, alt: 123.456, acc: 20.0)
      end
    end
  end

  # We submit temporal data from a phone in +03 to a server in -06.
  context "with date/time types" do
    let(:form) { create(:form, question_types: %w[datetime date time]) }
    let(:data) do
      {
        form.c[0] => "2017-07-12T16:40:00.000+03",
        form.c[1] => "2017-07-01",
        form.c[2] => "14:30:00.000+03"
      }
    end

    around do |example|
      in_timezone("Saskatchewan") { example.run } # Saskatchewan is -06
    end

    it "retains timezone information for datetime but not time" do
      expect(nodes[0].set.answers[0].datetime_value.to_s).to eq "2017-07-12 07:40:00 -0600"
      #puts nodes[1].set.answers[0].date_value.to_s
      expect(nodes[1].set.answers[0].date_value.to_s).to eq "2017-07-01"
      puts nodes[2].set.answers[0].time_value.to_s
      expect(nodes[2].set.answers[0].time_value.to_s).to eq "2000-01-01 14:30:00 UTC"
      expect(nodes[0].set.answers[0].value).to be_nil
      expect(nodes[1].set.answers[0].value).to be_nil
      expect(nodes[2].set.answers[0].value).to be_nil
    end
  end

  context "with prefilled timestamps" do
    let(:form) { create(:form, question_types: %w[formstart formend]) }
    let(:data) do
      {
        form.c[0] => "2017-07-12T16:40:12.000-06",
        form.c[1] => "2017-07-12T16:42:43.000-06"
      }
    end

    around do |example|
      in_timezone("Saskatchewan") { example.run } # Saskatchewan is -06
    end

    it "accepts data normally" do
      expect(nodes[0].set.answers[0].datetime_value).to eq Time.zone.parse("2017-07-12 16:40:12 -06")
      expect(nodes[1].set.answers[0].datetime_value).to eq Time.zone.parse("2017-07-12 16:42:43 -06")
    end
  end

  context "with other question types" do
    let(:form) { create(:form, question_types: %w[text long_text decimal]) }
    let(:data) do
      {
        form.c[0] => "Quick",
        form.c[1] => "The quick brown fox jumps over the lazy dog",
        form.c[2] => "9.6"
      }
    end

    it "processes correct values" do
      expect(nodes[0].set.answers[0].value).to eq "Quick"
      expect(nodes[1].set.answers[0].value).to eq "The quick brown fox jumps over the lazy dog"
      expect(nodes[2].set.answers[0].value).to eq "9.6"
    end
  end
end
