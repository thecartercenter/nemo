# frozen_string_literal: true

require "rails_helper"

describe ODK::CodeMapper do
  let(:form) { create(:form, question_types: ["text", %w[text text], "multilevel_select_one"]) }
  let(:mapper) { ODK::CodeMapper.instance }

  context "item_id_for_code" do
    it "retrieves group for group code" do
      group = form.c[1]
      code = "grp#{group.id}"
      expect(mapper.item_id_for_code(code)).to eq(group.id)
    end

    it "retrieves questioning for questioning with code starting with qing" do
      form_item = form.c[0]
      code = "qing#{form_item.id}"
      expect(mapper.item_id_for_code(code)).to eq(form_item.id)
    end

    it "handles multilevel codes" do
      multilevel_qing = form.c[2]
      codes = multilevel_qing.subqings.map { |sq| mapper.code_for_item(sq) }
      codes.each do |code|
        expect(mapper.item_id_for_code(code)).to eq(multilevel_qing.id)
      end
    end

    it "returns option id for node" do
      option_node = form.c[2].option_set.c[0]
      code = "on#{option_node.id}"
      expect(mapper.item_id_for_code(code)).to eq(option_node.id)
    end

    it "errors when code has unknown format" do
      code = "group123"
      expect do
        mapper.item_id_for_code(code)
      end.to raise_error(SubmissionError, "Code format unknown: #{code}.")
    end
  end
end
