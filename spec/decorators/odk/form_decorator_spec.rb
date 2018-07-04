# frozen_string_literal: true

require "rails_helper"

describe Odk::FormDecorator, :odk do
  include_context "odk rendering"

  describe "needs_manifest?" do
    let(:decorated_form) { decorate(form) }
    subject(:needs_manifest?) { decorated_form.needs_manifest? }

    context "for form with single level option sets only" do
      let(:form) { create(:form, question_types: %w[select_one]) }
      it { is_expected.to be_falsey }
    end

    context "for form with multi level option set" do
      let(:form) { create(:form, question_types: %w[select_one multilevel_select_one]) }
      it { is_expected.to be_truthy }
    end
  end
end
