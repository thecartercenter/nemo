# frozen_string_literal: true

require "rails_helper"

describe Odk::FormDecorator, :odk do
  include_context "odk rendering"

  describe "needs_manifest?" do
    let(:decorated_form) { decorate(form) }
    subject(:needs_manifest?) { decorated_form.needs_manifest? }

    before do
      Odk::OptionSetDecorator # Force autoload # rubocop:disable Lint/Void
      # Stub threshold constant so that multilevel opt set is rendered normally,
      # but super_multilevel opt set is rendered as external.
      stub_const("Odk::OptionSetDecorator::EXTERNAL_CSV_METHOD_THRESHOLD", 7)
    end

    describe "multilevel option sets" do
      context "for form with small multilevel option sets only" do
        let(:form) { create(:form, question_types: %w[multilevel_select_one]) }
        it { is_expected.to be(false) }
      end

      context "for form with large multilevel option set" do
        let(:form) { create(:form, question_types: %w[select_one super_multilevel_select_one]) }
        it { is_expected.to be(true) }
      end
    end

    describe "media prompts" do
      let(:form) { create(:form, question_types: %w[text]) }

      context "with media prompt question" do
        before do
          form.c[0].question.update!(media_prompt: audio_fixture("powerup.mp3"))
        end

        context "when question is visible" do
          it { is_expected.to be(true) }
        end

        context "when question is invisible" do
          before do
            form.c[0].update!(hidden: true)
          end

          it { is_expected.to be(false) }
        end
      end

      context "without media prompt question" do
        it { is_expected.to be(false) }
      end
    end
  end
end
