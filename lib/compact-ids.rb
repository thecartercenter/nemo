require 'yaml'
require 'mysql2'
require 'pp'
require_relative 'foreign-keys'

IGNORE_TABLES = %w(sessions)

db_config = YAML.load_file('config/database.yml')[ENV['RAILS_ENV'] || 'development']
db = Mysql2::Client.new(db_config)

foreign_keys = Hash[*FOREIGN_KEYS.map do |table, keys|
  [table, keys.map{ |k| k[:ref_tbl] || k[:polymorphic] || k[:ancestry] ? k : k.merge(ref_tbl: k[:col].gsub(/_id$/, 's')) }]
end.flatten(1)]

transform = {}

tables = db.query('SHOW TABLES').map{ |r| r.first.last } - IGNORE_TABLES

db.query('SET foreign_key_checks = 0')

tables.each { |t| db.query("ALTER TABLE `#{t}` DISABLE KEYS") }

db.query('BEGIN')

puts 'Calculating mappings'

tables.each do |table|
  next unless db.query("SHOW COLUMNS FROM #{table}").map{ |c| c['Field']}.include?('id')
  ids = db.query("SELECT id FROM #{table} ORDER BY id").to_a.map{ |r| r['id'] }
  transform[table] = {}.tap do |h|
    ids.each_with_index { |id, i| h[id] = i+1 }
  end
end

puts 'Setting new IDs'

transform.each do |table, items|
  puts table
  items.each do |old_id, new_id|
    db.query("UPDATE #{table} SET id = #{new_id} WHERE id = #{old_id}")
  end
end

puts 'Updating foreign keys'

foreign_keys.each do |table, keys|
  puts table
  db.query("SELECT * FROM #{table}").each do |row|
    updates = {}
    keys.each do |key|
      unless row[key[:col]].nil?
        if key[:ancestry]
          updates[key[:col]] = row[key[:col]].split('/').map{ |id| transform[table][id.to_i] }.join('/')
        else
          updates[key[:col]] = transform[key[:ref_tbl]][row[key[:col]]] || 'NULL'
          puts "Found orphan #{key[:col]} #{row[key[:col]]} for #{table}" if updates[key[:col]] == 'NULL'
        end
      end
    end
    next if updates.empty?
    clause = updates.map{ |field, new_val| "#{field} = #{new_val}" }.join(', ')
    db.query("UPDATE #{table} SET #{clause} WHERE id = #{row['id']}")
  end
end

db.query('COMMIT')

tables.each { |t| db.query("ALTER TABLE `#{t}` ENABLE KEYS") }