require 'rails_helper'

# will go away with answer arranger. Specs failing due to trying to edit tree
describe OldAnswerInstance do
  describe "normalize" do
    let(:form) { create(:form, question_types: ["integer", {repeating: {items: %w[integer integer]}}]) }
    let(:response) do
      create(:response, form: form, answer_values: [
        111,
        {repeating: [
          [222, 333],
          [444, 555],
          [777, 888]
        ]}
      ])
    end
    let(:root_instance) do
      AnswerArranger.new(response, placeholders: :none, dont_load_answers: true).build
    end

    context "with blank instance" do
      before do
        # Add blank instance
        form.sorted_children[1].sorted_children.each_with_index do |qing, i|
          response.answers.build(inst_num: 5, questioning: qing, response: response, value: "")
        end
      end

      xit "marks blank instance for destruction" do
        response
        expect(response.answers.map(&:inst_num)).to eq [1, 1, 1, 2, 2, 3, 3, 5, 5]
        root_instance.normalize
        expect(response.answers.map(&:marked_for_destruction?)).to(
          eq([false, false, false, false, false, false, false, true, true]))
      end
    end

    context "with non-contiguous instance numbers" do
      before do
        # Change instance nums of 3rd instance to 5.
        response.answers.each{ |a| a.inst_num = 5 if a.inst_num == 3 }
      end

      xit "makes contiguous" do
        expect(response.answers.map(&:inst_num)).to eq [1, 1, 1, 2, 2, 5, 5]
        root_instance.normalize
        expect(response.answers.map(&:inst_num)).to eq [1, 1, 1, 2, 2, 3, 3]
      end
    end

    context "with instance marked for destruction" do
      before do
        # Mark 2nd instance for deletion.
        response.answers.each{ |a| a.mark_for_destruction if a.inst_num == 2 }
      end

      xit "makes remaining instances contiguous" do
        expect(response.answers.map(&:inst_num)).to eq [1, 1, 1, 2, 2, 3, 3]
        root_instance.normalize
        expect(response.answers.map(&:inst_num)).to eq [1, 1, 1, 2, 2, 2, 2]
      end
    end
  end
end
