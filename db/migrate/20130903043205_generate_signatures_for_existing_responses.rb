class GenerateSignaturesForExistingResponses < ActiveRecord::Migration
  def change
    Response.where(:signature => nil).each do |response|      
      response.check_if_duplicate_and_save
    end
  end
end
