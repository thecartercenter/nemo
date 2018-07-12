# frozen_string_literal: true

require "rails_helper"

module Odk
  describe FormItemDecorator, :odk, :reset_factory_sequences, database_cleaner: :truncate do
    include_context "odk rendering"

    describe "xpath methods" do
      let!(:form) do
        create(:form, question_types: [ # root (grp1)
          "text",         # sc[0] (q1)
          [               # sc[1] (grp3)
            "text",       # --> sc[0] (q2)
            "text",       # --> sc[1] (q3)
            [             # --> sc[2] (grp6)
              "integer",  # --> --> sc[0] (q4)
            ],
            [             # --> sc[3] (grp8)
              "text",     # --> --> sc[0] (q5)
              [           # --> --> sc[1] (grp10)
                "text"    # --> --> --> sc[0] (q6)
              ]
            ]
          ],
          "text" # sc[2] (q7)
        ])
      end

      let(:root) { decorate(form.root_group) }
      let(:q1) { decorate(form.c[0]) }
      let(:grp3) { decorate(form.c[1]) }
      let(:q2) { decorate(form.c[1].c[0]) }
      let(:q3) { decorate(form.c[1].c[1]) }
      let(:grp6) { decorate(form.c[1].c[2]) }
      let(:q4) { decorate(form.c[1].c[2].c[0]) }
      let(:grp8) { decorate(form.c[1].c[3]) }
      let(:q5) { decorate(form.c[1].c[3].c[0]) }
      let(:grp10) { decorate(form.c[1].c[3].c[1]) }
      let(:q6) { decorate(form.c[1].c[3].c[1].c[0]) }
      let(:q7) { decorate(form.c[2]) }

      describe "absolute_xpath" do
        it do
          expect(q4.absolute_xpath).to eq "/data/grp#{grp3.id}/grp#{grp6.id}/qing#{q4.id}"
          expect(q6.absolute_xpath).to eq "/data/grp#{grp3.id}/grp#{grp8.id}/grp#{grp10.id}/qing#{q6.id}"
        end
      end

      describe "xpath_to" do
        it "returns the relative xpath when staying on same level within group" do
          expect(q3.xpath_to(q2)).to eq "../qing#{q2.id}"
        end

        it "returns the relative xpath when going up within group" do
          expect(q4.xpath_to(q2)).to eq "../../qing#{q2.id}"
        end

        it "returns the absolute xpath when going from top-level to top-level" do
          expect(q1.xpath_to(q7)).to eq "/data/qing#{q7.id}"
        end

        it "returns the absolute xpath when going from group to top-level" do
          expect(q4.xpath_to(q1)).to eq "/data/qing#{q1.id}"
        end

        it "uses indexed-repeat when going down into a subgroup" do
          expect(q5.xpath_to(q6)).to eq "indexed-repeat(/data/grp#{grp3.id}/grp#{grp8.id}/grp#{grp10.id}"\
          "/qing#{q6.id},/data/grp#{grp3.id},position(../..),/data/grp#{grp3.id}/grp#{grp8.id},position(..),"\
          "/data/grp#{grp3.id}/grp#{grp8.id}/grp#{grp10.id},1)"
        end

        it "uses indexed-repeat when going from group to group" do
          expect(q4.xpath_to(q6)).to eq "indexed-repeat(/data/grp#{grp3.id}/grp#{grp8.id}"\
          "/grp#{grp10.id}/qing#{q6.id},"\
          "/data/grp#{grp3.id},position(../..),/data/grp#{grp3.id}/grp#{grp8.id},1,/data/grp#{grp3.id}"\
          "/grp#{grp8.id}/grp#{grp10.id},1)"
        end

        it "uses indexed-repeat when going from top-level to group" do
          expect(q1.xpath_to(q4)).to eq "indexed-repeat(/data/grp#{grp3.id}/grp#{grp6.id}/qing#{q4.id},"\
            "/data/grp#{grp3.id},1,/data/grp#{grp3.id}/grp#{grp6.id},1)"
        end

        it "handles root to subitem properly" do
          expect(root.xpath_to(q2)).to eq "indexed-repeat(/data/grp#{grp3.id}/qing#{q2.id},"\
          "/data/grp#{grp3.id},1)"
        end

        it "handles root to top-level item properly" do
          expect(root.xpath_to(q7)).to eq "/data/qing#{q7.id}"
        end
      end
    end
  end
end
