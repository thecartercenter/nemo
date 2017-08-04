require 'spec_helper'

describe QingGroupOdkPartitioner do

  let(:form) { create(:form, question_types: [["text","text","multilevel_select_one","integer"],["text", "text", "text"]]) }

  it "splits qing groups in order to remove multilevel questions from them" do
    result = QingGroupOdkPartitioner.new.fragment(form.sorted_children.first)
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

  it "return nil if there isn't a multilevel question on it" do
    result = QingGroupOdkPartitioner.new.fragment(form.sorted_children.last)
    expect(result).to be_nil
  end

  it "returns nil for the root group" do
    result = QingGroupOdkPartitioner.new.fragment(form.root_group)
    expect(result).to be_nil
  end

  it "returns nil if has no children" do
    result = QingGroupOdkPartitioner.new.fragment(form.sorted_children.first.sorted_children.first)
    expect(result).to be_nil
  end
end
