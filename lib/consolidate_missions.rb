require 'rubygems'
require 'mysql'

# assumes the main DB has already been db:schema:load'd and db:seedy'd


MISSION_DBS = [{
    :mission => "Oklahoma 2011",
    :offset => 3200,
    :database => "cceom_cc_ok",
    :username => "cceom_cc_ok",
    :password => "02870107"
  },{
    :mission => "Liberia 2011",
    :offset => 27000,
    :database => "cceom_cc_lr",
    :username => "cceom_cc_lr",
    :password => "t1ckleME"
  },{
    :mission => "Liberia 2011 Runoff",
    :offset => 53000,
    :database => "cceom_cc_lr2",
    :username => "cceom_cc_lr2",
    :password => "t1ckleME"
  },{
    :mission => "Egypt 2012",
    :offset => 157000,
    :database => "cceom_elmo_eg",
    :username => "cceom_elmo_eg",
    :password => "t1ckleME"
  },{
    :mission => "Libya 2012",
    :offset => 17000,
    :database => "cceom_elmo_ly",
    :username => "cceom_elmo_ly",
    :password => "t1ckleME"
  }
]

MAIN_DB = { :database => "cceom_elmo_main", :username => "cceom_elmo_main", :password => "telefunkuku" }
TEMP_DB = { :database => "cceom_temp1", :username => "cceom_temp1", :password => "temp" }

TABLES_TO_COPY = %w(answers assignments broadcast_addressings broadcasts choices conditions form_types forms missions
 option_sets option_settings options questionings questions report_fields report_groupings report_reports responses settings translations users)

TABLES_TO_LOOKUP_IN_MAIN = {
  :question_types => ["questions.question_type_id", "report_fields.question_type_id"], 
  :report_aggregations => ["report_reports.aggregation_id"],
  :report_response_attributes => ["report_fields.attrib_id"],
  :roles => ["assignments.role_id"]
}

dont_shift = TABLES_TO_LOOKUP_IN_MAIN.values.flatten.collect{|f| f.split(".").last}.uniq

def connect(params)
  Mysql.connect('localhost', params[:username], params[:password], params[:database])
end

def clear_tables(dbname, con)
  puts "Deleting from tables in #{dbname}"
  TABLES_TO_COPY.each do |t|
    #puts "Deleting from table #{dbname}.#{t}"
    con.query("DELETE FROM `#{t}`") 
  end
end

def copy_tables(from_params, from_con, to_params, to_con)
  puts "Copying tables from #{from_params[:database]} to #{to_params[:database]}"
  
  # build & run cmd
  dump_cmd = "/usr/bin/mysqldump --skip-opt --no-create-info --extended-insert -u #{from_params[:username]} -p#{from_params[:password]} #{from_params[:database]} #{TABLES_TO_COPY.join(' ')}"
  load_cmd = "/usr/bin/mysql -u #{to_params[:username]} -p#{to_params[:password]} #{to_params[:database]}"
  %x[#{dump_cmd} > dump_tmp.sql]
  puts %x[#{dump_cmd} | #{load_cmd}]
end

# connect
temp_db = connect(TEMP_DB)
main_db = connect(MAIN_DB)

# delete all rows in appropriate tables from main db
clear_tables(MAIN_DB[:database], main_db)

max_ids_by_table = Hash[*TABLES_TO_COPY.collect{|t| [t, 0]}.flatten]

total_offset = 0

# for each db
MISSION_DBS.each_with_index do |mission_db_params, mission_db_idx|

  mission_db = connect(mission_db_params)
  
  # delete all rows in appropriate tables from temp db
  clear_tables(TEMP_DB[:database], temp_db)

  # copy everything from old mission db to the temp db
  copy_tables(mission_db_params, mission_db, TEMP_DB, temp_db)

  # rename the default mission to the correct name
  m_name = mission_db_params[:mission]
  m_compact_name = m_name.gsub(" ", "").downcase
  temp_db.query("UPDATE missions SET name = '#{m_name}', compact_name = '#{m_compact_name}'")
  
  # first we offset everything in all tables
  # for each table
  puts "Shifting id's"
  TABLES_TO_COPY.each do |t|
    
    # add offset to all ID's
    #puts "Shifting all #{t} ids by #{total_offset}"
    temp_db.query("UPDATE #{t} SET id = id + #{total_offset} + 1000000")
    temp_db.query("UPDATE #{t} SET id = id - 1000000")
    
    # update the offset
    #r = temp_db.query("SELECT MAX(id) FROM #{t}")
    #max_ids_by_table[t] = r.fetch_row[0].to_i
    #puts "Updated offset to #{max_ids_by_table[t]}"
  
    # for each col ending in _id, add offset
    res = temp_db.query("SHOW COLUMNS FROM #{t} WHERE Field LIKE '%_id'")
    while row = res.fetch_hash
      col = row['Field']
      
      # don't shift certain columns
      next if dont_shift.include?(col)
      
      #puts "Shifting all #{t}.#{col}'s by #{total_offset}"
      temp_db.query("UPDATE #{t} SET #{col} = #{col} + #{total_offset} + 1000000")
      temp_db.query("UPDATE #{t} SET #{col} = #{col} - 1000000")
    end
    
  end

  # then we go through the TABLES_TO_LOOKUP_IN_MAIN and lookup their values and build translatioin keys by name
  # for each table in TABLES_TO_LOOKUP_IN_MAIN
  TABLES_TO_LOOKUP_IN_MAIN.each_pair do |t, fks|
    name_to_id_hash = {}

    # lookup value in new table and store
    res = main_db.query("SELECT id, name FROM #{t}")
    while row = res.fetch_hash do
      name_to_id_hash[row['name']] = row['id']
    end
    puts "Built lookup hash #{name_to_id_hash.inspect}"
    
    # for each foreign key col
    fks.each do |fk|
      fk_table, fk_field = fk.split(".")
      # for each row in that col
      res = temp_db.query("SELECT id, #{fk_field} FROM #{fk_table}")
      while row = res.fetch_hash
        next if row[fk_field].nil?
        name = mission_db.query("SELECT name FROM #{t} WHERE #{t}.id = #{row[fk_field]}").fetch_row.first
        
        # hard-coded name substitutions
        name = "Coordinator" if name == "Program Staff" || name == "Admin"
        
        looked_up = name_to_id_hash[name]

        # update the value
        #puts "Updating #{fk} for row ##{row['id']} from #{row[fk_field]} (#{name}) to #{looked_up}"
        if looked_up.nil?
          puts "Couldn't find matching row when updating #{fk} for row ##{row['id']} from #{row[fk_field]} (#{name})"
        else
          temp_db.query("UPDATE #{fk_table} SET #{fk_field} = '#{looked_up}' WHERE id = '#{row['id']}'")
        end
      end
    end
  end
  
  # fix duplicate user logins
  # for each user in temp table
  res1 = temp_db.query("SELECT id, login FROM users")
  while new_user_row = res1.fetch_hash do
    
    # get its ID and login
    new_id, login = new_user_row['id'], new_user_row['login']
    
    # if there is an existing user in the main table with the same login name, get its ID
    res2 = main_db.query("SELECT id FROM users WHERE login = '#{login}'")
    if old_user_row = res2.fetch_hash
      old_id = old_user_row['id']
    
      # delete the row in the main table (so we replace with the newer one)
      puts "Deleting duplicate user #{login} from main db" 
      main_db.query("DELETE FROM users WHERE id = '#{old_id}'")
      
      # update all responses, assignments, and broadcast addressings in the main db with a matching user_id to the newer ID
      %w(responses assignments broadcast_addressings).each do |ut|
        puts "Updating referring #{ut}'s in main db from #{old_id} to #{new_id}"
        main_db.query("UPDATE #{ut} SET user_id = '#{new_id}' WHERE user_id = '#{old_id}'")
      end
    end
  end
  
  # copy all rows in appropriate tables to the main table -- everything should match by now
  copy_tables(TEMP_DB, temp_db, MAIN_DB, main_db)
  
  total_offset += mission_db_params[:offset]
end

# update auto increment counters in all appropriate tables to appropriate values
puts "Updating auto incs to #{total_offset}"
TABLES_TO_COPY.each do |t|
  main_db.query("ALTER TABLE #{t} AUTO_INCREMENT = #{total_offset}")
end