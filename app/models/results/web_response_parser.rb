# frozen_string_literal: true

module Results
  # Builds (does not save) an answer tree based on answer data in a web response.
  class WebResponseParser
    TOP_LEVEL_PARAMS = %i[
      id
      questioning_id
      value
      option_node_id
      "datetime_value(1i)"
      "datetime_value(2i)"
      "datetime_value(3i)"
      "datetime_value(4i)"
      "datetime_value(5i)"
      "datetime_value(6i)"
      "date_value(1i)"
      "date_value(2i)"
      "date_value(3i)"
      "time_value(1i)"
      "time_value(2i)"
      "time_value(3i)"
      "time_value(4i)"
      "time_value(5i)"
      "time_value(6i)"
      media_object_id
      choices_attributes
    ].freeze

    # replace choices_attributes top level param with a hash representing nested attributes
    PERMITTED_PARAMS = TOP_LEVEL_PARAMS.without(:choices_attributes)
      .append(choices_attributes: %w[option_node_id checked]).freeze

    # Expects ActionController::Parameters instance without required or permitted set, which is
    # a hash representing the structure of an answer heirarchy that comes with a web response.
    # Returns an unsaved answer tree object based on the hash
    def parse(web_answer_hash)
      tree_root = new_tree_node(web_answer_hash[:root], nil)
      add_children(web_answer_hash[:root][:children], tree_root)
    end

    private

    def new_tree_node(web_hash_node, tree_parent)
      type = web_hash_node[:type].constantize
      clean_params = web_hash_node.slice(*TOP_LEVEL_PARAMS).permit(PERMITTED_PARAMS)
      all_attrs = clean_params.merge(rank_attributes(type, tree_parent))
      type.new(all_attrs)
    end

    def add_children(web_hash_children, tree_parent)
      web_hash_children.each_pair do |_k, v|
        next if ignore_node?(v)
        child = new_tree_node(v, tree_parent)
        tree_parent.children << child
        add_children(v[:children], child) if v[:children]
      end
      tree_parent
    end

    def ignore_node?(web_hash_node)
      web_hash_node[:relevant] == "false" || web_hash_node[:_destroy] == "true"
    end

    # Rank and inst_num will go away at end of answer refactor
    def rank_attributes(type, tree_parent)
      {
        new_rank: tree_parent.present? ? tree_parent.children.length : 0,
        rank: tree_parent.is_a?(AnswerSet) ? tree_parent.children.length + 1 : 1,
        inst_num: inst_num(type, tree_parent)
      }
    end

    # Inst num will go away at end of answer refactor; this makes it work with answer arranger
    def inst_num(type, tree_parent)
      if tree_parent.is_a?(AnswerGroupSet) # repeat group
        tree_parent.children.length + 1
      elsif [Answer, AnswerSet, AnswerGroupSet].include?(type)
        tree_parent.inst_num
      else
        1
      end
    end
  end
end
