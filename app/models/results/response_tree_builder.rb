# frozen_string_literal: true

module Results
  # Builds a response tree from a form object
  class ResponseTreeBuilder
    attr_accessor :form

    def initialize(form)
      self.form = form
    end

    def build
      root = AnswerGroup.new
      add_level(form.root_group.children, root)
      root
    end

    private

    def add_level(form_nodes, response_node)
      form_nodes.sort_by(&:rank).each do |form_node|
        if form_node.class == QingGroup && form_node.repeatable?
          add_repeat_group(form_node, response_node)
        elsif form_node.class == QingGroup
          add_non_repeat_group(response_node, form_node)
        elsif form_node.multilevel?
          add_multilevel(form_node, response_node)
        else
          add_child(Answer, response_node, form_node)
        end
      end
    end

    def add_repeat_group(form_node, response_node)
      group_set = add_child(AnswerGroupSet, response_node, form_node)
      group = AnswerGroup.new(questioning_id: form_node.id, new_rank: 1)
      group_set.children << group
      add_level(form_node.children, group) if form_node.children?
    end

    def add_non_repeat_group(response_node, form_node)
      group = add_child(AnswerGroup, response_node, form_node)
      add_level(form_node.children, group) if form_node.children?
    end

    def add_multilevel(form_node, response_node)
      set = add_child(AnswerSet, response_node, form_node)
      form_node.levels.each_with_index do |_level, index|
        set.children << Answer.new(questioning_id: form_node.id, new_rank: index + 1)
      end
    end

    def add_child(type, response_node, form_node)
      child = type.new(questioning_id: form_node.id, new_rank: form_node.rank)
      response_node.children << child
      child
    end
  end
end
