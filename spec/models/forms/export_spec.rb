# frozen_string_literal: true

require "rails_helper"

describe Forms::Export do
  context "simple form" do
    let!(:simpleform) { create(:form, question_types: %w[text integer text]) }

    it "should produce the correct csv" do
      exporter = Forms::Export.new(simpleform)
      expect(exporter.to_csv).to eq("csv")
    end
  end
end
