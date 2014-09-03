# CAN'T COMMENT OUT FKS SINCE IT RUINS ADDING OFFSETS
# NEED TO DEAL WITH ANCESTRY WHEN INCREMENTING

require 'yaml'
require 'mysql2'
require 'pp'
require_relative 'foreign-keys'

OFFSET = 1_000_000

list = File.read(ARGV[0]) or raise 'Error reading list file.'
list = list.split("\n").reject(&:empty?).map{ |r| r.split(',') }.map{ |r| [r[0], r[1].to_i] }

db_config = YAML.load_file('config/database.yml')[ENV['RAILS_ENV'] || 'development']
db = Mysql2::Client.new(db_config)

foreign_keys = Hash[*FOREIGN_KEYS.map do |table, keys|
  [table, keys.map{ |k| k[:ref_tbl] || k[:polymorphic] ? k : k.merge(ref_tbl: k[:col].gsub(/_id$/, 's')) }]
end.flatten(1)]

foreign_keys_inv = {}.tap do |inv|
  foreign_keys.each do |table, keys|
    keys.each do |key|
      unless key[:no_rev]
        inv[key[:ref_tbl]] ||= []
        inv[key[:ref_tbl]] << {col: key[:col], tbl: table}
      end
    end
  end
end

id_cols = Hash[*foreign_keys.map{ |table, keys| [table, keys.map{ |k| k[:col] } << 'id'] }.flatten(1)]

# Remove no_fwd keys.
foreign_keys.each do |table, keys|
  keys.each do |key|
    foreign_keys[table].delete(key) if key[:no_fwd]
  end
end

history = Hash[*list.map{ |r| [r, []] }.flatten(1)]

# For each in list:
loop do
  list2 = list.clone
  list.each do |row|

    # For each foreign key in table, add to list.
    foreign_keys[row[0]].each do |fk|
      result = db.query("SELECT #{fk[:col]} FROM #{row[0]} WHERE id = #{row[1]}").to_a
      next if result.empty?
      refd_id = result.first[fk[:col]]
      next if refd_id.nil?
      next if list2.include?([fk[:ref_tbl], refd_id])
      new_row = [fk[:ref_tbl], refd_id]
      list2 << new_row
      history[new_row] = history[row] + [[row, :fwd]]
    end

    # For each foreign key that references the table, add all entries in that table that reference the row to the list.
    (foreign_keys_inv[row[0]] || []).each do |fki|
      new_rows = db.query("SELECT id FROM #{fki[:tbl]} WHERE #{fki[:col]} = #{row[1]}").to_a.map{ |r| [fki[:tbl], r['id']] }
      new_rows -= list2
      list2 += new_rows
      new_rows.each do |nr|
        history[nr] = history[row] + [[row, :rev]]
      end
    end
  end
  old_size = list.size
  list = list2.uniq.sort
  break if list.size == old_size
end

# Create temp tables, dump, and remove.
ids_by_tbl = {}.tap{ |a| list.each{ |r| (a[r[0]] ||= []) << r[1] } }
ids_by_tbl.keys.each do |t|
  cols = db.query("SHOW COLUMNS FROM #{t}").map{ |c| c['Field']}
  db.query("DROP TABLE IF EXISTS __#{t}")
  id_cols[t].each do |col|
    cols[cols.index(col)] = "#{col} + #{OFFSET} AS #{col}"
  end
  cols.map!{ |c| c =~ / AS /i ? c : "`#{c}`"} # Add backticks.
  db.query("CREATE TABLE __#{t} SELECT #{cols.join(',')} FROM #{t} WHERE id IN (#{ids_by_tbl[t].join(',')})")
  pass = db_config['password'].nil? ? '' : "-p#{db_config['password']}"
  dump = `mysqldump -h #{db_config['host']} -u #{db_config['username']} #{pass} --skip-triggers --compact --no-create-info #{db_config['database']} __#{t}`
  puts dump.gsub('INSERT INTO `__', 'INSERT INTO `')
  db.query("DROP TABLE __#{t}")
end
