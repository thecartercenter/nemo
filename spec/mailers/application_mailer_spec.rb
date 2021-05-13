# frozen_string_literal: true

require "rails_helper"

# For testing only
class SampleMailer < ApplicationMailer
  def sample(mission = nil)
    @mission = mission
    mail(to: "foo@example.com", subject: "Test", body: "Test")
  end
end

# Covers common behavior to all mailers.
describe ApplicationMailer do
  let(:mission1) { create(:mission) }
  let(:mission2) { create(:mission) }

  context "with default theme" do
    it "has correct site name in from address" do
      expect(SampleMailer.sample(mission1).deliver_now["From"].value).to eq("NEMO <nemo@example.com>")
      expect(SampleMailer.sample(mission2).deliver_now["From"].value).to eq("NEMO <nemo@example.com>")
      expect(SampleMailer.sample.deliver_now["From"].value).to eq("NEMO <nemo@example.com>")
    end
  end

  context "with different themes" do
    before do
      mission2.setting.update!(theme: "elmo")
      Setting.root.update!(theme: "elmo")
    end

    after do
      Setting.root.update!(theme: "nemo")
    end

    it "has correct site name in from address" do
      # Call mailer several times to make sure @mission instance variable works as expected
      expect(SampleMailer.sample(mission1).deliver_now["From"].value).to eq("NEMO <nemo@example.com>")
      expect(SampleMailer.sample(mission2).deliver_now["From"].value).to eq("ELMO <nemo@example.com>")
      expect(SampleMailer.sample.deliver_now["From"].value).to eq("ELMO <nemo@example.com>")
    end
  end
end
