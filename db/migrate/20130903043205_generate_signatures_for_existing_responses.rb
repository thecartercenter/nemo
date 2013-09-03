class GenerateSignaturesForExistingResponses < ActiveRecord::Migration
  def change
    Response.where(:signature => nil).each do |response|
      
      # generate signature
      response.generate_duplicate_signature
      
      # flag response as duplicate or not
      response.duplicate = response.find_duplicates.empty? || response.find_duplicates.nil? ? 0 : 1
      
      response.save!
    end
  end
end
