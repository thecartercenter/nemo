class Response < ActiveRecord::Base
  belongs_to :mission
  belongs_to :form

  def generate_shortcode
    shortcode_chars = ("a".."z").to_a + ("0".."9").to_a

    begin
      response_code = 5.times.map { shortcode_chars.sample }.join
      mission_code = mission.shortcode
      form_code = form.code
      shortcode = [mission_code, form_code, response_code].join("-")
      self.shortcode = shortcode
    end while Response.exists?(shortcode: self.shortcode)
  end
end

class GenerateShortcodesForResponses < ActiveRecord::Migration[4.2]
  def up
    Response.includes(:form, :mission).find_each do |response|
      response.generate_shortcode
      response.save!
    end
  end

  def down
    Response.update_all(shortcode: nil)
  end
end
