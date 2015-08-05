class RevertAnswersToInnoDb < ActiveRecord::Migration
  def up
    execute('ALTER TABLE answers ENGINE=InnoDB');
  end

  def down
    execute('ALTER TABLE answers ENGINE=MyISAM')
  end
end
