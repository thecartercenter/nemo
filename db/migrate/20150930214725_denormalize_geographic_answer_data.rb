class DenormalizeGeographicAnswerData < ActiveRecord::Migration[4.2]
  def up
    create_new_columns
    copy_location_info_to_new_columns
  end

  def down
    remove_column :answers, :latitude
    remove_column :answers, :longitude

    remove_column :choices, :latitude
    remove_column :choices, :longitude
  end

  # Latitude: -90 to 90 with six decimals
  # Longitude: -180 to 180 with six decimals
  def create_new_columns
    add_column :answers, :latitude, :decimal, precision: 8, scale: 6
    add_column :answers, :longitude, :decimal, precision: 9, scale: 6

    add_column :choices, :latitude, :decimal, precision: 8, scale: 6
    add_column :choices, :longitude, :decimal, precision: 9, scale: 6
  end

  def copy_location_info_to_new_columns
    location_answers = fetch_all_answers_with_locations

    puts "Coping #{location_answers.size} answer values"
    location_answers.each_with_index do |answer, i|
      puts "#{i}" if i % 100 == 0

      # Regular location question
      if answer.value
        lat, long = answer.value.split(' ')
        setLatLongValueOnNewColumns(answer, BigDecimal.new(lat), BigDecimal.new(long))
      # Select one location question
      elsif answer.option
        setLatLongValueOnNewColumns(answer, answer.option.latitude, answer.option.longitude)
      # Select multiple
      else
        answer.choices.each do |choice|
          setLatLongValueOnNewColumns(choice, choice.option.latitude, choice.option.longitude)
        end
      end
    end
  end

  def fetch_all_answers_with_locations
    Answer.find_by_sql(["SELECT DISTINCT `answers`.* FROM `answers`
      INNER JOIN `responses` ON `responses`.`id` = `answers`.`response_id`
      INNER JOIN `form_items` ON `form_items`.`id` = `answers`.`questioning_id` AND `form_items`.`type` IN ('Questioning')
      INNER JOIN `questions` ON `questions`.`id` = `form_items`.`question_id`
      LEFT JOIN `option_sets` ON `questions`.`option_set_id` = `option_sets`.`id`
      LEFT JOIN `options` ON `option_sets`.`allow_coordinates` = 1 AND `questions`.`qtype_name` = 'select_one' AND `answers`.`option_id` = `options`.`id`
      LEFT JOIN `choices` ON `option_sets`.`allow_coordinates` = 1 AND `questions`.`qtype_name` = 'select_multiple' AND `answers`.`id` = `choices`.`answer_id`
      LEFT JOIN `options` AS `choice_options` ON `choices`.`option_id` = `choice_options`.`id` WHERE (
        (`questions`.`qtype_name` = 'location' AND `answers`.`value` IS NOT NULL)
        OR (`options`.`latitude` IS NOT NULL AND `options`.`longitude` IS NOT NULL)
        OR (`choice_options`.`latitude` IS NOT NULL AND `choice_options`.`longitude` IS NOT NULL)
      )"])
  end

  def setLatLongValueOnNewColumns(object, lat, long)
    object.latitude = lat
    object.longitude = long

    object.save
  end
end
