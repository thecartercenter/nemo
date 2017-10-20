require "spec_helper"

module Odk
  describe FormItemDecorator, :odk, :reset_factory_sequences, database_cleaner: :truncate do
    describe "xpath methods" do
      let!(:form) do
        create(:form, question_types: [ # root (grp1)
          "text",       # c[0] (q1)
          [             # c[1] (grp3)
            "text",     # --> c[0] (q2)
            "text",     # --> c[1] (q3)
            [           # --> c[2] (grp6)
              "integer",   # --> --> c[0] (q4)
            ],
            [           # --> c[3] (grp8)
              "text",   # --> --> c[0] (q5)
              [         # --> --> c[1] (grp10)
                "text"  # --> --> --> c[0] (q6)
              ]
            ]
          ],
          "text"        # c[2] (q7)
        ])
      end

      let(:root) { decorate(form.root_group) }
      let(:q1) { decorate(form.c[0]) }
      let(:q2) { decorate(form.c[1].c[0]) }
      let(:q3) { decorate(form.c[1].c[1]) }
      let(:q4) { decorate(form.c[1].c[2].c[0]) }
      let(:q5) { decorate(form.c[1].c[3].c[0]) }
      let(:q6) { decorate(form.c[1].c[3].c[1].c[0]) }
      let(:q7) { decorate(form.c[2]) }

      describe "absolute_xpath" do
        it do
          expect(q4.absolute_xpath).to eq "/data/grp3/grp6/q4"
          expect(q6.absolute_xpath).to eq "/data/grp3/grp8/grp10/q6"
        end
      end

      describe "xpath_to" do
        it "returns the relative xpath when staying on same level within group" do
          expect(q3.xpath_to(q2)).to eq "../q2"
        end

        it "returns the relative xpath when going up within group" do
          expect(q4.xpath_to(q2)).to eq "../../q2"
        end

        it "returns the absolute xpath when going from top-level to top-level" do
          expect(q1.xpath_to(q7)).to eq "/data/q7"
        end

        it "returns the absolute xpath when going from group to top-level" do
          expect(q4.xpath_to(q1)).to eq "/data/q1"
        end

        it "uses indexed-repeat when going down into a subgroup" do
          expect(q5.xpath_to(q6)).to eq "indexed-repeat(/data/grp3/grp8/grp10/q6,"\
            "/data/grp3,position(../..),/data/grp3/grp8,position(..),/data/grp3/grp8/grp10,1)"
        end

        it "uses indexed-repeat when going from group to group" do
          expect(q4.xpath_to(q6)).to eq "indexed-repeat(/data/grp3/grp8/grp10/q6,"\
            "/data/grp3,position(../..),/data/grp3/grp8,1,/data/grp3/grp8/grp10,1)"
        end

        it "uses indexed-repeat when going from top-level to group" do
          expect(q1.xpath_to(q4)).to eq "indexed-repeat(/data/grp3/grp6/q4,"\
            "/data/grp3,1,/data/grp3/grp6,1)"
        end

        it "handles root to subitem properly" do
          expect(root.xpath_to(q2)).to eq "indexed-repeat(/data/grp3/q2,/data/grp3,1)"
        end

        it "handles root to top-level item properly" do
          expect(root.xpath_to(q7)).to eq "/data/q7"
        end
      end
    end

    describe "#relevance" do
      let(:form) { create(:form, question_types: %w(integer integer)) }
      let(:qing) { form.c[1] }
      subject { decorate(qing).relevance }

      before do
        allow(qing).to receive(:display_conditions).and_return(disp_conds)
        qing.display_if = display_if
      end

      context "with multiple conditions" do
        let(:disp_conds) { [double(to_odk: "foo"), double(to_odk: "bar")] }

        context "with display_if all_met" do
          let(:display_if) { "all_met" }
          it { is_expected.to eq "(foo) and (bar)" }
        end

        context "with display_if any_met" do
          let(:display_if) { "any_met" }
          it { is_expected.to eq "(foo) or (bar)" }
        end
      end

      context "with one condition" do
        let(:disp_conds) { [double(to_odk: "foo")] }

        context "with display_if all_met" do
          let(:display_if) { "all_met" }
          it { is_expected.to eq "foo" }
        end

        context "with display_if any_met" do
          let(:display_if) { "any_met" }
          it { is_expected.to eq "foo" }
        end
      end

      context "with no conditions" do
        let(:disp_conds) { [] }
        let(:display_if) { "always" }
        it { is_expected.to be_nil }
      end
    end

    def decorate(obj)
      Odk::DecoratorFactory.decorate(obj)
    end
  end
end
