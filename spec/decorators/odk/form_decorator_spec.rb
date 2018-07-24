# frozen_string_literal: true

require "rails_helper"

describe Odk::FormDecorator, :odk do
  include_context "odk rendering"

  describe "needs_manifest?" do
    let(:decorated_form) { decorate(form) }
    subject(:needs_manifest?) { decorated_form.needs_manifest? }

    describe "multilevel option sets" do
      context "for form with single level option sets only" do
        let(:form) { create(:form, question_types: %w[select_one]) }
        it { is_expected.to be false }
      end

      context "for form with multi level option set" do
        let(:form) { create(:form, question_types: %w[select_one multilevel_select_one]) }
        it { is_expected.to be true }
      end
    end

    describe "audio prompts" do
      let(:form) { create(:form, question_types: %w[text]) }

      context "with audio prompt question" do
        before do
          form.c[0].question.update!(audio_prompt: audio_fixture("powerup.mp3"))
        end

        context "when question is visible" do
          it { is_expected.to be true }
        end

        context "when question is invisible" do
          before do
            form.c[0].update!(hidden: true)
          end

          it { is_expected.to be false }
        end
      end

      context "without audio prompt question" do
        it { is_expected.to be false }
      end
    end
  end
end
