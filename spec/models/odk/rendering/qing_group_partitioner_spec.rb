require "rails_helper"

module Odk
  describe QingGroupPartitioner, :odk do
    let(:form) { create(:form, question_types: question_types) }
    let(:question_types) { [["text","text","multilevel_select_one","integer"],["text", "text", "text"]] }
    let(:result) { described_class.new.fragment(QingGroupDecorator.new(group)) }

    context "with regular group" do
      let(:group) { form.sorted_children.first }

      it "splits qing groups in order to remove multilevel questions from them" do
        expect(result.size).to eq(4)
        expect(result.map(&:class).uniq).to eq [QingGroupFragment]

        expect(result[0].children.map(&:qtype_name)).to eq %w(text text)

        expect(result[1].children.count).to eq 1
        expect(result[1].children.first.multilevel?).to be true
        expect(result[1].level).to eq 1
        expect(result[2].children.count).to eq 1
        expect(result[2].children.first.multilevel?).to be true
        expect(result[2].level).to eq 2

        expect(result[3].children.map(&:qtype_name)).to eq %w(integer)
      end
    end

    context "with no multilevel questions" do
      let(:group) { form.sorted_children.last }

      it "return nil" do
        expect(result).to be_nil
      end
    end

    context "with multilevel question as first child" do
      let(:group) { form.sorted_children.first }
      let(:question_types) { [["multilevel_select_one","integer"]] }

      it "splits correctly" do
        expect(result[0].sorted_children.first.multilevel?).to be true
        expect(result[1].sorted_children.first.multilevel?).to be true
        expect(result[2].sorted_children.first.multilevel?).to be_falsey
      end
    end

    context "with root group" do
      let(:group) { form.root_group }

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "with no children" do
      let(:group) { form.sorted_children.first.sorted_children.first }

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end
end
