# frozen_string_literal: true

module Results
  # Builds and saves response tree, with all blank answers, from a form object.
  class BlankResponseTreeBuilder
    attr_accessor :response

    delegate :form, to: :response

    def initialize(response)
      self.response = response
    end

    def build
      root = AnswerGroup.create!(form_item: form.root_group, response: response)
      add_level(form.root_group.sorted_children, root)
      root.associate_response(response)
      response.root_node = root
      # TODO: We can remove the `validate: false` once various validations are
      # removed from the response model
      response.save(validate: false)
      root
    end

    private

    def add_level(form_nodes, response_node)
      form_nodes.each do |form_node|
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
      group = add_child(AnswerGroup, group_set, form_node)
      add_level(form_node.sorted_children, group) if form_node.children?
    end

    def add_non_repeat_group(response_node, form_node)
      group = add_child(AnswerGroup, response_node, form_node)
      add_level(form_node.sorted_children, group) if form_node.children?
    end

    def add_multilevel(form_node, response_node)
      set = add_child(AnswerSet, response_node, form_node)
      form_node.levels.each do
        add_child(Answer, set, form_node)
      end
    end

    def add_child(type, response_node, form_node)
      child = type.new(
        questioning_id: form_node.id,
        response: response,
        new_rank: response_node.children.size
      )
      # We can't validate yet because there's no value.
      child.save(validate: false)
      response_node.children << child
      child
    end
  end
end
