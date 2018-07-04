class AddFkConstraintsForStandards < ActiveRecord::Migration[4.2]
  def up
    %w(forms questionings questions conditions option_sets optionings options).each do |t|
      # first we have to nullify any standard_id columns that reference non existing objects
      fixed = update("UPDATE #{t} t LEFT OUTER JOIN #{t} t2 ON t.standard_id = t2.id
        SET t.standard_id = NULL
        WHERE t.standard_id IS NOT NULL AND t2.id IS NULL");

      puts "Fixed #{fixed} #{t}"

      # these will raise error if standard is deleted before copies.
      add_foreign_key(t, t, :column => "standard_id")
    end
  end

  def down
  end
end
