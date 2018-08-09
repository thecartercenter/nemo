# frozen_string_literal: true

module Results
  # Builds and saves response tree, with all blank answers, from a form object.
  class BlankResponseTreeBuilder
    attr_accessor :response, :options

    delegate :form, to: :response

    def initialize(response)
      self.response = response
    end

    def build
      root = response.build_root_node(
        type: "AnswerGroup",
        form_item: form.root_group,
        response: response,
        new_rank: 0
      )
      add_level(form.root_group.sorted_children, root)
      response.root_node
    end

    private

    def add_level(form_nodes, response_node)
      form_nodes.each do |form_node|
        unless form_node.hidden
          if form_node.class == QingGroup && form_node.repeatable?
            add_repeat_group(form_node, response_node)
          elsif form_node.class == QingGroup
            add_non_repeat_group(response_node, form_node)
          elsif form_node.multilevel?
            add_multilevel(form_node, response_node)
          else
            add_child("Answer", response_node, form_node)
          end
        end
      end
    end

    def add_repeat_group(form_node, response_node)
      group_set = add_child("AnswerGroupSet", response_node, form_node)
      group = add_child("AnswerGroup", group_set, form_node)
      add_level(form_node.sorted_children, group) if form_node.children?
    end

    def add_non_repeat_group(response_node, form_node)
      group = add_child("AnswerGroup", response_node, form_node)
      add_level(form_node.sorted_children, group) if form_node.children?
    end

    def add_multilevel(form_node, response_node)
      set = add_child("AnswerSet", response_node, form_node)
      form_node.levels.each do
        add_child("Answer", set, form_node)
      end
    end

    def add_child(type, response_node, form_node)
      response_node.children.build(
        type: type,
        questioning_id: form_node.id,
        response: response,
        new_rank: response_node.children.size,
        rank: response_node.children.size + 1
      )
    end
  end
end
