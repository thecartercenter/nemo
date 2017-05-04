require "spec_helper"

describe XMLSubmission do
  include ODKSubmissionSupport
  context "with simple form" do
    before do
      @form = create(:form, question_types: ["integer", ["integer", "integer"]])
      @form.publish!
      @response = create(:response, form: @form)
      @files = { xml_submission_file: StringIO.new(build_odk_submission(@form, repeat: true)) }
    end

    describe ".new" do
      it "creates a submission and parses it to populate response" do
        submission = XMLSubmission.new(response: @response, files: @files, source: "odk")
        response = submission.response
        response.answers.each_with_index do |answer|
          expect(answer.inst_num).to eq nil unless answer.from_group?
        end
        expect(response.answers.where("inst_num > ?", 1).count).to eq 2
        expect(response).to be_valid
      end
    end
  end

  context "with complex form" do

    before do
      @form = create(:form,
        question_types: %w(select_one multilevel_select_one select_multiple integer multilevel_select_one)
      )
      @form.publish!
      @response = create(:response, form: @form)
      @files = { xml_submission_file: StringIO.new(build_odk_submission(@form, repeat: true)) }
      # Without a source, XMLSubmission will not pre-populate
      @submission = XMLSubmission.new(response: @response, files: @files)
    end

    describe "populate_from_hash" do
      it "populates a response with a hash" do
        questions = @form.questions

        # set short names for options
        cat = questions[0].option_set.sorted_children.first
        plant, oak = questions[1].option_set.sorted_children
        cat2, dog2 = questions[2].option_set.sorted_children
        animal = questions[4].option_set.sorted_children.first

        @submission.populate_from_hash({
          "q#{questions[0].id}" => "on#{cat.id}",
          "q#{questions[1].id}_1" => "on#{plant.id}",
          "q#{questions[1].id}_2" => "on#{oak.id}",
          "q#{questions[2].id}" => "on#{cat2.id} on#{dog2.id}",
          "q#{questions[3].id}" => "123",
          "q#{questions[4].id}_1" => "on#{animal.id}",
          "q#{questions[4].id}_2" => "none",
        })
        resp = @submission.response

        nodes = AnswerArranger.new(resp).build.nodes

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
  end
end
