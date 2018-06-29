class RevertAnswersToInnoDb < ActiveRecord::Migration[4.2]
  def up
    execute('ALTER TABLE answers ENGINE=InnoDB');
  end

  def down
    execute('ALTER TABLE answers ENGINE=MyISAM')
  end
end
