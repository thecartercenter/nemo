# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: media_objects
#
#  id         :uuid             not null, primary key
#  type       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  answer_id  :uuid
#
# Indexes
#
#  index_media_objects_on_answer_id  (answer_id)
#
# Foreign Keys
#
#  media_objects_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

# rubocop:disable Layout/MultilineHashBraceLayout
# rubocop:disable Layout/HashAlignment
# rubocop:disable Style/WordArray
describe Media::Object do
  let(:media_file) { create(:media_image) }
  let(:responses) { [] }

  it "has attachment" do
    expect(media_file.item.attached?).to be(true)
  end

  context "with simple answer" do
    let(:form) { create(:form, question_types: ["text"]) }
    let(:response) { create(:response, form: form, answer_values: "foo") }
    let(:answer) { response.c[0] }

    it "sets filename after association with answer" do
      expect(media_file.item.filename.to_s).to eq("the_swing.jpg")
      media_file.update!(answer: answer)
      expect(media_file.item.filename.to_s).to match(/nemo-.+-.+.jpg/)
    end
  end

  context "with nested groups" do
    let(:repeat_form) do
      create(:form,
        question_types:
          ["integer",
           {repeating:
             {name: "Person",
              items: [
                "text",
                {repeating: {name: "Eyes", items: ["image"]}}
              ]}}])
    end

    let(:media_jpg) { create(:media_image, :jpg) }
    let(:media_png) { create(:media_image, :png) }

    before do
      create_response(form: repeat_form, answer_values: [
        1,
        {repeating: [
          ["Jill", {repeating: [[media_jpg], [media_png]]}],
          ["Wynn", {repeating: [[media_jpg], [media_png]]}]
        ]}
      ])
    end

    it "should have correct filename" do
      r = Response.last
      filename1 = r.root_node.c[1].c[1].c[1].c[0].c[0].media_object.item.blob.filename.to_s
      filename2 = r.root_node.c[1].c[1].c[1].c[1].c[0].media_object.item.blob.filename.to_s

      expect(filename1).to match(/-Person2-Eyes1-.+.jpg/)
      expect(filename2).to match(/-Person2-Eyes2-.+.png/)
    end
  end

  context "Regular nested groups" do
    let(:repeat_form) do
      create(:form,
        question_types: [
          [["image", "image"]]
        ])
    end

    let!(:media_jpg) { create(:media_image, :jpg) }
    let!(:media_png) { create(:media_image, :png) }

    before do
      create_response(form: repeat_form, answer_values: [
        [[media_jpg, media_png]]
      ])
    end

    it "should have correct and unique filenames" do
      r = Response.last
      media = r.root_node.c[0].c[0].c
      # get question code
      code1 = media_jpg.answer.question.code
      code2 = media_png.answer.question.code
      filename1 = media[0].media_object.item.blob.filename.to_s
      expect(filename1).to include(code1)
      filename2 = media[1].media_object.item.blob.filename.to_s
      expect(filename2).to include(code2)
    end
  end

  context "Repeat group with group inside" do
    let(:repeat_form) do
      create(:form,
        question_types: [
          {repeating:
            {name: "RC",
             items: [
               "text",
               # inner group
               [
                 "text",
                 "image",
                 "image"
               ]
             ]
            }
          }
        ])
    end
    let!(:media_jpg) { create(:media_image, :jpg) }
    let!(:media_png) { create(:media_image, :png) }
    let!(:media_jpg2) { create(:media_image, :jpg) }
    let!(:media_png2) { create(:media_image, :png) }

    before do
      create_response(form: repeat_form, answer_values: [
        {repeating:
          [
            ["touchstone", ["alice", media_jpg, media_png]],
            ["greatoak", ["rhys", media_jpg2, media_png2]]
          ]
        }
      ])
    end

    it "should have correct and unique filenames" do
      r = Response.first
      filename1 = r.c[0].c[1].c[1].c[2].media_object.item.blob.filename.to_s
      filename2 = r.c[0].c[1].c[1].c[1].media_object.item.blob.filename.to_s
      filename3 = r.c[0].c[0].c[1].c[1].media_object.item.blob.filename.to_s

      expect(filename1).to match(/-RC2-Image/)
      expect(filename2).to match(/-RC2-Image/)
      expect(filename3).to match(/-RC1-Image/)
    end
  end

  context "One group, one repeat group" do
    let(:repeat_form) do
      create(:form,
        question_types: [
          [
            {repeating:
              {name: "Person",
               items: ["image"]
            }}
          ]
        ])
    end

    let!(:media_jpg) { create(:media_image, :jpg) }
    let!(:media_png) { create(:media_image, :png) }

    before do
      create_response(form: repeat_form, answer_values: [
        [{repeating: [[media_jpg], [media_png]]}]
      ])
    end

    it "should have correct and unique filenames" do
      r = Response.last
      filename1 = r.root_node.c[0].c[0].c[1].c[0].media_object.item.blob.filename.to_s
      group_name = r.root_node.c[0].group_name.gsub(/\s+/, "_").to_s
      expect(filename1).to include(group_name)
      expect(filename1).to match(/-Person2-.+.png/)

      filename2 = r.root_node.c[0].c[0].c[0].c[0].media_object.item.blob.filename.to_s
      expect(filename2).to include(group_name)
      expect(filename2).to match(/-Person1-.+.jpg/)
    end
  end

  def create_response(params)
    responses << create(:response, params)
  end
end
# rubocop:enable Layout/MultilineHashBraceLayout
# rubocop:enable Layout/HashAlignment
# rubocop:enable Style/WordArray
