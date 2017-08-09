require "spec_helper"

module Odk
  describe QingDecorator, :odk, database_cleaner: :truncate do
    context "with deeply nested qings" do
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
          ]
        ])
      end

      let(:qing) { described_class.decorate(form.sorted_children[1].sorted_children[2].sorted_children[0]) }
      let(:other_qing) do
        described_class.decorate(form.sorted_children[1].sorted_children[3].sorted_children[1].sorted_children[0])
      end

      it "returns the absolute xpath", :reset_factory_sequences do
        expect(qing.absolute_xpath).to eq "/data/grp3/grp6/q4"
        expect(other_qing.absolute_xpath).to eq "/data/grp3/grp8/grp10/q6"
      end

      it "returns the relative xpath", :reset_factory_sequences do
        expect(qing.relative_xpath(other_qing)).to eq "../../grp8/grp10/q6"
      end
    end
  end
end
