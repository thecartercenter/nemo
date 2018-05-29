# frozen_string_literal: true

module Results
  # Builds a response tree from a form object
  class ResponseTreeBuilder
    def initialize(form)
      @form = form
    end

    def build
      @rn = AnswerGroup.new
      add_level(@form.root_group.children, @rn)
      @rn
    end

    private

    def add_level(form_nodes, response_node)
      form_nodes.each do |form_node|
        if form_node.class == QingGroup && form_node.repeatable?
          add_repeat_group(form_node, response_node)
        elsif form_node.class == QingGroup
          add_group(response_node, form_node)
        elsif form_node.multilevel?
          add_multilevel(form_node, response_node)
        else
          add_child(Answer, response_node, form_node)
        end
      end
    end

    def add_child(type, response_node, form_node)
      response_node.children << type.new(questioning_id: form_node.id, new_rank: form_node.rank)
    end

    def add_group(response_node, form_node)
      add_child(AnswerGroup, response_node, form_node)
      add_level(form_node.children, response_node.children.last) if form_node.children.present?
    end

    def add_repeat_group(form_node, response_node)
      add_child(AnswerGroupSet, response_node, form_node)
      response_node.children.last.children << AnswerGroup.new(questioning_id: form_node.id, new_rank: 1)
      add_level(form_node.children, response_node.children[0].children[0]) if form_node.children.present?
    end

    def add_multilevel(form_node, response_node)
      add_child(AnswerSet, response_node, form_node)
      form_node.levels.each_with_index do |_level, index|
        response_node.children.last.children << Answer.new(
          questioning_id: form_node.id,
          new_rank: index+1
        )
      end
    end
  end
end
