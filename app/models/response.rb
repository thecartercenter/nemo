require 'xml'

class Response < ActiveRecord::Base
  belongs_to(:form, :include => :questions)
  has_many(:answers, :include => {:question => {:option_set => :options}})
  belongs_to(:place)

  def self.create_from_xml(xml, user)
    # parse xml
    doc = XML::Parser.string(xml).parse

    # get form id
    form_id = doc.root["id"] or raise ArgumentError.new("No form id.")
    form_id = form_id.to_i
    
    # create response object
    resp = new(:form_id => form_id, :user_id => user ? user.id : nil)
    qs = begin resp.form.questions rescue raise ArgumentError.new("Invalid form id.") end
    
    # loop over each child tag and create hash of values
    values = {}; doc.root.children.each{|c| values[c.name] = c.first? ? c.first.content : nil}
    
    # loop over all the questions in the form and create answers
    # if we find a location question, set the response location
    # if we find a start_timestamp question, save it also
    place_bits = {}
    start_time = nil
    qs.each do |q|
      # get value from hash
      v = values[q.code]
      # add answers
      resp.answers += q.new_answers_from_str(v)
      # reverse-lookup the first location type question we find
      place_bits[:coords] = (v ? v.split(" ")[0..1] : false) if place_bits[:coords].nil? && q.is_location?
      place_bits[:addr] = v || false if place_bits[:addr].nil? && q.is_address?
      # check for start_timestamp
      start_time = v ? Time.parse(v) : false if start_time.nil? && q.is_start_timestamp?
    end
    
    # set the observe time
    resp.observed_at = start_time || nil
    
    # try to get the response's place based on the place bits
    resp.place = Place.find_or_create_with_bits(place_bits)
    
    # save the works
    resp.save
  end
end
