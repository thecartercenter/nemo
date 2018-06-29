class OptionSet < ActiveRecord::Base; end
class OptionNode < ActiveRecord::Base; has_ancestry; end

class CreateOptionNodesForOptionings < ActiveRecord::Migration[4.2]
  require 'pp'

  def up
    transaction do

      # For all non-copy option sets.
      OptionSet.where(standard_id: nil).each do |set|
        puts "Option Set #{set.id} (#{set.name}) -------------------------------------------------------------------------------------"

        # Create root node.
        root = OptionNode.create!({option_set_id: set.id}.merge(%w(is_standard mission_id).map_hash{ |a| set.send(a) }))
        set.update_column(:root_node_id, root.id)

        puts "Created root node #{root.inspect}"

        # Create root nodes for copies.
        root_copies = {}
        OptionSet.where(:standard_id => set.id).each do |copy|
          copy_root = OptionNode.create!({option_set_id: copy.id, standard_id: root.id}.merge(%w(is_standard mission_id).map_hash{ |a| set.send(a) }))
          copy.update_column(:root_node_id, copy_root.id)
          root_copies[copy.mission_id] = copy_root # Store for recursion
          puts "Created root node copy #{copy_root.inspect}"
        end

        # Create nodes recursively for all children.
        create_nodes(set: set, parent_id: nil, parent_node: root, parent_copies: root_copies)
      end
    end
  end

  def down
  end

  def create_nodes(params)
    # Create nodes.
    parent_clause = params[:parent_id].nil? ? 'IS NULL' : "= '#{params[:parent_id]}'"
    oings = exec_query("SELECT *, optionings.id AS id FROM optionings, options
      WHERE option_set_id = '#{params[:set].id}' AND parent_id #{parent_clause}
        AND optionings.option_id = options.id")
    oings.each do |oing|
      puts "#{oing['name_translations']}---------------------------------------------"

      # Create node for main.
      node = OptionNode.create!(%w(option_set_id option_id mission_id is_standard rank).map_hash{ |a| oing[a] })
      node.update_attributes!(parent: params[:parent_node])
      puts "Created child node #{node.inspect}"

      # Create for copies.
      node_copies = {}
      exec_query("SELECT * FROM optionings WHERE standard_id = '#{oing['id']}'").each do |copy|
        copy_node = OptionNode.create!({standard_id: node.id}.merge(%w(option_set_id option_id mission_id is_standard rank).map_hash{ |a| copy[a] }))
        raise "Parent copy for mission #{copy['mission_id']} not found" unless (parent_copy = params[:parent_copies][copy['mission_id']])
        copy_node.update_attributes!(parent: parent_copy)
        puts "Created child node copy #{copy_node.inspect}"
        node_copies[copy['mission_id']] = copy_node
      end

      create_nodes(params.merge(parent_id: oing['id'], parent_node: node, parent_copies: node_copies))
    end
  end
end
