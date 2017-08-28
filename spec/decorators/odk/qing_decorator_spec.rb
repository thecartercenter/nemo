require "spec_helper"

module Odk
  describe QingDecorator, :odk, :reset_factory_sequences, database_cleaner: :truncate do
    let!(:form) do
      create(:form, question_types: [ # root (grp1)
        "text",       # sorted_children[0] (qing2 -> q1)
        [             # sorted_children [1] (grp3)
          "text",     # --> sorted_children[0] (qing4 -> q2)
          "text",     # --> sorted_children[1] (qing5 -> q3)
          [           # --> sorted_children[2] (grp6)
            "integer",   # --> --> sorted_children[0] (qing6 -> q4)
          ],
          [           # --> sorted_children[3] (grp8)
            "text",   # --> --> sorted_children[0] (qing9 -> q5)
            [         # --> --> sorted_children[1] (grp10)
              "text"  # --> --> --> sorted_children[0] (qing11 -> q6)
            ]
          ]
        ],
        "text"        # sorted_children[2] (qing12 -> q7)
      ])
    end

    let(:qing2) { described_class.decorate(form.sorted_children[0]) }
    let(:qing4) { described_class.decorate(form.sorted_children[1].sorted_children[0]) }
    let(:qing5) { described_class.decorate(form.sorted_children[1].sorted_children[1]) }
    let(:qing6) { described_class.decorate(form.sorted_children[1].sorted_children[2].sorted_children[0]) }
    let(:qing9) { described_class.decorate(form.sorted_children[1].sorted_children[3].sorted_children[0]) }
    let(:qing11) { described_class.decorate(form.sorted_children[1].sorted_children[3].
      sorted_children[1].sorted_children[0]) }
    let(:qing12) { described_class.decorate(form.sorted_children[2]) }

    describe "absolute_xpath" do
      it do
        expect(qing6.absolute_xpath).to eq "/data/grp3/grp6/q4"
        expect(qing11.absolute_xpath).to eq "/data/grp3/grp8/grp10/q6"
      end
    end

    describe "xpath_to" do
      it "returns the relative xpath when staying on same level within group" do
        expect(qing5.xpath_to(qing4)).to eq "../q2"
      end

      it "returns the relative xpath when going up within group" do
        expect(qing6.xpath_to(qing4)).to eq "../../q2"
      end

      it "returns the absolute xpath when going from top-level to top-level" do
        expect(qing2.xpath_to(qing12)).to eq "/data/q7"
      end

      it "returns the absolute xpath when going from group to top-level" do
        expect(qing6.xpath_to(qing2)).to eq "/data/q1"
      end

      it "uses indexed-repeat when going down into a subgroup" do
        expect(qing9.xpath_to(qing11)).to eq "indexed-repeat(/data/grp3/grp8/grp10/q6,"\
          "/data/grp3,position(../..),/data/grp3/grp8,position(..),/data/grp3/grp8/grp10,1)"
      end

      it "uses indexed-repeat when going from group to group" do
        expect(qing6.xpath_to(qing11)).to eq "indexed-repeat(/data/grp3/grp8/grp10/q6,"\
          "/data/grp3,position(../..),/data/grp3/grp8,1,/data/grp3/grp8/grp10,1)"
      end

      it "uses indexed-repeat when going from top-level to group" do
        expect(qing2.xpath_to(qing6)).to eq "indexed-repeat(/data/grp3/grp6/q4,"\
          "/data/grp3,1,/data/grp3/grp6,1)"
      end
    end
  end
end
