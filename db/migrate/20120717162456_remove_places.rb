class RemovePlaces < ActiveRecord::Migration
  def up
    transaction do
      # create locality, state, country, and full address questions
      short_txt_type = QuestionType.find_by_name("text")
      long_txt_type = QuestionType.find_by_name("long_text")
      loc = Question.create!(:code => "oldLocality", :question_type_id => short_txt_type,
        :name_eng => "Old Locality", :hint_eng => "Locality from the old place object.")
      sta = Question.create!(:code => "oldState", :question_type_id => short_txt_type,
        :name_eng => "Old State", :hint_eng => "State from the old place object.")
      cry = Question.create!(:code => "oldCountry", :question_type_id => short_txt_type,
        :name_eng => "Old Country", :hint_eng => "Country from the old place object.")
      adr = Question.create!(:code => "oldFullAddr", :question_type_id => long_txt_type,
        :name_eng => "Old Full Address", :hint_eng => "Full address from the old place object.")
      
      # for each form
      Form.all.each do |form|
        puts "Updating responses for form: '#{form.name}'"
        
        # add the question to the form
        loc_qing = form.questionings.create!(:question => loc)
        sta_qing = form.questionings.create!(:question => sta)
        cry_qing = form.questionings.create!(:question => cry)
        adr_qing = form.questionings.create!(:question => adr)
      
        # find gps question
        gps_type = QuestionType.find_by_name("location")
        gps_qing = form.questionings.select{|qing| qing.question.type == gps_type}.first
        
        form.responses.each do |resp|
          if resp.respond_to?(:answers) && pid = resp.place_id
            # get fields from place (can't use ORM b/c the code is gone)
            p = execute("SELECT loc.long_name AS locality, sta.long_name AS state, cry.long_name AS country, " +
              "p.full_name AS full_name, CONCAT(p.latitude, ' ', p.longitude) AS lat_lng " + 
              "FROM places p LEFT JOIN places loc on p.locality_id=loc.id " + 
              "LEFT JOIN places sta on p.state_id=sta.id " + 
              "LEFT JOIN places cry on p.country_id=cry.id " + 
              "WHERE p.id = #{pid}").fetch_hash
              
            # copy locality, state, country, and full address
            resp.answers.create!(:questioning => loc_qing, :value => p['locality'])
            resp.answers.create!(:questioning => sta_qing, :value => p['state'])
            resp.answers.create!(:questioning => cry_qing, :value => p['country'])
            resp.answers.create!(:questioning => adr_qing, :value => p['full_name'])

            # copy gps to gps question if available
            if gps_qing
              gps_ans = resp.answers.find_by_questioning_id(gps_qing.id)
              gps_ans = resp.answers.build(:questioning => gps_qing) if gps_ans.nil?
              gps_ans.value = p['lat_lng']
              gps_ans.save!
            end
          end
        end
        
      end
    end
    
    # remove places table and referencing fks
    drop_table(:places)
    drop_table(:place_types)
    drop_table(:place_creators)
    remove_column(:responses, :place_id)
  end

  def down
  end
end
