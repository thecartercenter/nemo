# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: media_objects
#
#  id                :uuid             not null, primary key
#  item_content_type :string(255)      not null
#  item_file_name    :string(255)      not null
#  item_file_size    :integer          not null
#  item_updated_at   :datetime         not null
#  type              :string(255)      not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  answer_id         :uuid
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
      puts media_file.item.filename.to_s
      expect(media_file.item.filename.to_s).to match(/nemo-.+-.+.jpg/)
    end
  end

  context "with nested groups" do
    let(:repeat_form) do
      create(:form,
        question_types:
          ["integer",                                  # 1
           {repeating: {name: "Person", items: [
             "text",                                   # 2
             {repeating: {name: "Eyes", items: ["image"]}}
            ]}
          }]
        )
    end

    let(:media_jpg) { create(:media_image, :jpg) }
    let(:media_png) { create(:media_image, :png) }
    let(:media_jpg) { create(:media_image, :tiff) }

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
      filename = r.root_node.c[1].c[1].c[1].c[0].c[0].media_object.item.blob.filename.to_s
      expect(filename).to match(/Person2-Eyes1.tiff/)
    end
  end

  def create_response(params)
    responses << create(:response, params)
  end
end
