class NormalizeUserFields < ActiveRecord::Migration[4.2]
  def up
    # set null falses
    change_column(:users, :login, :string, :null => false)
    change_column(:users, :name, :string, :null => false)
    change_column(:users, :updated_at, :datetime, :null => false)
    change_column(:users, :created_at, :datetime, :null => false)
    change_column(:users, :admin, :boolean, :null => false, :default => false)
    change_column(:users, :pref_lang, :string, :null => false)

    # fix blank emails
    execute("UPDATE users SET email = NULL WHERE email = ''")

    # add unique email index
    add_index(:users, :email, :unique => true)
  end

  def down
  end
end
