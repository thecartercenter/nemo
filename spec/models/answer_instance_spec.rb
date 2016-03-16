require 'spec_helper'

describe AnswerInstance do
  describe "normalize" do
    let(:form) { create(:form, question_types: ["integer", ["integer", "integer"]]) }
    let(:response) do
      create(:response, form: form, answer_values: [
        111,
        [:repeating,
          [222, 333],
          [444, 555]
        ]
      ])
    end
    let(:root_instance) do
      AnswerArranger.new(response, include_missing_answers: false, dont_load_answers: true).build
    end

    before do
      # Change instance nums of second instance to 4.
      # response.answers.each{ |a| a.inst_num = 4 if a.inst_num == 2 }

      # Add blank instance
      form.children[1].children.each_with_index do |qing, i|
        response.answers.build(inst_num: 4, questioning: qing, response: response, value: 111 * (i + 7))
      end
    end

    it "removes blank, non-persisted instances" do
      expect(response.answers.map(&:inst_num)).to eq [1, 1, 1, 2, 2, 4, 4]
      root_instance.normalize
      expect(response.answers.map(&:marked_for_destruction?)).to(
        eq([false, false, false, false, false, true, true]))
    end

    # it "ensures contiguous instance numbers" do
    #   expect(response.answers.map(&:inst_num)).to eq [1, 1, 1, 4, 4]
    #   root_instance.normalize
    #   expect(response.answers.map(&:inst_num)).to eq [1, 1, 1, 2, 2]
    # end

  end
end