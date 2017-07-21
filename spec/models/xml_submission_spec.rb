require "spec_helper"

describe XMLSubmission do
  include ODKSubmissionSupport

  let(:blank_response) { create(:response, form: form) }
  let(:xml) { build_odk_submission(form, data: data) }
  let(:files) { {xml_submission_file: StringIO.new(xml)} }
  let(:submission) { XMLSubmission.new(response: blank_response, source: "odk", files: files) }
  let(:response) { submission.response }
  let(:nodes) { AnswerArranger.new(response).build.nodes }

  before do
    form.publish!
  end

  context "with a repeat group and two instances" do
    let(:form) { create(:form, question_types: ["integer", ["integer", "integer"]]) }
    let(:data) do
      {
        form.c[0] => "123",
        form.c[1] => [
          {
            form.c[1].c[0] => "456",
            form.c[1].c[1] => "789"
          },{
            form.c[1].c[0] => "12",
            form.c[1].c[1] => "34"
          }
        ]
      }
    end

    it "processes repeats correctly" do
      expect(nodes[0].set.answers[0].value).to eq "123"
      expect(nodes[0].set.answers[0].rank).to eq 1

      expect(nodes[1].instances[0].nodes[0].set.answers[0].value).to eq "456"
      expect(nodes[1].instances[0].nodes[1].set.answers[0].value).to eq "789"

      expect(nodes[1].instances[1].nodes[0].set.answers[0].value).to eq "12"
      expect(nodes[1].instances[1].nodes[1].set.answers[0].value).to eq "34"
    end
  end

  context "with complex selects" do
    let(:form) do
      create(:form,
        question_types: %w(select_one multilevel_select_one select_multiple integer multilevel_select_one)
      )
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
    let(:form) do
      create(:form,
        question_types: %w(location)
      )
    end
    let(:data) do
      {
        form.c[0] => "12.3456 -76.99388"
      }
    end

    it "processes correct values" do
      expect(nodes[0].set.answers[0].value).to eq "12.345600 -76.993880"
      expect(nodes[0].set.answers[0].latitude).to eq 12.3456
      expect(nodes[0].set.answers[0].longitude).to eq -76.99388
    end
  end

  context "with date/time types" do
    let(:form) do
      create(:form,
        question_types: %w(datetime date time)
      )
    end
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

    it "discards timezone information in favor of current zone" do
      expect(nodes[0].set.answers[0].datetime_value).to eq Time.zone.parse("2017-07-12 16:40 -06")
      expect(nodes[1].set.answers[0].date_value).to eq Date.parse("2017-07-01")
      expect(nodes[2].set.answers[0].time_value).to eq Time.zone.parse("2000-01-01 14:30 -06").utc
      expect(nodes[0].set.answers[0].value).to be_nil
      expect(nodes[1].set.answers[0].value).to be_nil
      expect(nodes[2].set.answers[0].value).to be_nil
    end
  end

  context "with other question types" do
    let(:form) do
      create(:form,
        question_types: %w(text long_text decimal)
      )
    end
    let(:data) do
      {
        form.c[0] => "Quick",
        form.c[1] => "The quick brown fox jumps over the lazy dog",
        form.c[2] => "9.6",
        form.c[3] => "12.3456 -76.99388"
      }
    end

    it "processes correct values" do
      expect(nodes[0].set.answers[0].value).to eq "Quick"
      expect(nodes[1].set.answers[0].value).to eq "The quick brown fox jumps over the lazy dog"
      expect(nodes[2].set.answers[0].value).to eq "9.6"
    end
  end
end
