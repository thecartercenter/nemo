namespace :db do
  desc "Find orphaned records. Set DELETE=true to delete any discovered orphans."
  task :find_orphans => :environment do

    found = false

    model_base = Rails.root.join('app/models')

    Dir[model_base.join('**/*.rb').to_s].each do |filename|

      # get namespaces based on dir name
      namespaces = (File.dirname(filename)[model_base.to_s.size+1..-1] || '').split('/').map{|d| d.camelize}.join('::')

      # skip concerns folder
      next if namespaces == "Concerns"

      # get class name based on filename and namespaces
      class_name = File.basename(filename, '.rb').camelize
      klass = "#{namespaces}::#{class_name}".constantize

      next unless klass.ancestors.include?(ActiveRecord::Base)

      orphans = Hash.new

      klass.reflect_on_all_associations(:belongs_to).each do |belongs_to|
        assoc_name, field_name = belongs_to.name.to_s, belongs_to.foreign_key.to_s

        if belongs_to.options[:polymorphic]
          foreign_type_field = field_name.gsub('_id', '_type')
          foreign_types = klass.unscoped.select("DISTINCT(#{foreign_type_field})")
          foreign_types = foreign_types.collect { |r| r.send(foreign_type_field) }

          foreign_types.sort.each do |foreign_type|
            related_sql = foreign_type.constantize.unscoped.select(:id).to_sql

            finder = klass.unscoped.where("#{foreign_type_field} = '#{foreign_type}'")
            finder.where("#{field_name} NOT IN (#{related_sql})").each do |orphan|
              orphans[orphan] ||= Array.new
              orphans[orphan] << [assoc_name, field_name]
            end
          end
        else
          class_name = (belongs_to.options[:class_name] || assoc_name).classify
          related_sql = class_name.constantize.unscoped.select(:id).to_sql

          finder = klass.unscoped
          finder.where("#{field_name} NOT IN (#{related_sql})").each do |orphan|
            orphans[orphan] ||= Array.new
            orphans[orphan] << [assoc_name, field_name]
          end
        end
      end

      orphans.sort_by { |record, data| record.id }.each do |record, data|
        found = true
        data.sort_by(&:first).each do |assoc_name, field_name|
          puts "#{record.class.name}##{record.id} #{field_name} is present, but #{assoc_name} doesn't exist" + (ENV['DELETE'] ? ' -- deleting' : '')
          record.delete if ENV['DELETE']
        end
      end
    end

    puts "No orphans found" unless found
  end
end