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
    PERMITTED_PARAMS = (TOP_LEVEL_PARAMS.dup - [:choices_attributes])
      .append(choices_attributes: %w[option_node_id checked]).freeze

    def initialize
    end

    # Expects ActionController::Parameters instance without required or permitted set
    def parse(data)
      root = new_node(data[:root], nil)
      add_children(data[:root][:children], root)
    end

    def add_children(children, parent_node)
      children.each_pair do |_k, v|
        next if ignore_node?(v)
        child = new_node(v, parent_node)
        parent_node.children << child
        add_children(v[:children], child) if v[:children]
      end
      parent_node
    end

    def new_node(data_node, parent)
      type = data_node[:type].constantize
      clean_params = data_node.slice(*TOP_LEVEL_PARAMS).permit(
        [].concat(PERMITTED_PARAMS)
      )
      rank_attributes = rank_attributes(type, parent)
      all_attrs = clean_params.merge(rank_attributes)
      type.new(all_attrs)
    end

    def ignore_node?(data_node)
      data_node[:relevant] == "false" || data_node[:_destroy] == "true"
    end

    # Rank and inst_num will go away at end of answer refactor
    def rank_attributes(type, parent)
      {
        new_rank: parent.present? ? parent.children.length : 0,
        rank: parent.is_a?(AnswerSet) ? parent.children.length + 1 : 1,
        inst_num: inst_num(type, parent)
      }
    end

    # Inst num will go away at end of answer refactor; this makes it work with answer arranger
    def inst_num(type, parent)
      if parent.is_a?(AnswerGroupSet) # repeat group
        parent.children.length + 1
      elsif [Answer, AnswerSet, AnswerGroupSet].include? type
        parent.inst_num
      else
        1
      end
    end
  end
end
