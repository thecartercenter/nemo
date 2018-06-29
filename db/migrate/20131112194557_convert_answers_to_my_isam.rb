class ConvertAnswersToMyIsam < ActiveRecord::Migration[4.2]
  def up
    # have to delete all the foreign keys as myisam doesn't support them
    %w(answers_option_id_fk answers_questioning_id_fk answers_response_id_fk).each{|fk| execute("ALTER TABLE answers DROP FOREIGN KEY #{fk}")}
    execute('ALTER TABLE choices DROP FOREIGN KEY choices_answer_id_fk')

    # now do the conversion
    execute('ALTER TABLE answers ENGINE=MyISAM')
  end

  def down
  end
end
