# frozen_string_literal: true

module Sms
  # Class for building response tree to mirror form tree, specifically in the context of SMS, where
  # things are flattened out.
  class ResponseTreeBuilder
    attr_reader :answer_groups

    def initialize
      # mapping from qing group ID -> answer group
      @answer_groups = {}
    end

    def add_answer(parent, attribs)
      build_child(parent, "Answer", **attribs)
    end

    def build_or_find_parent_node_for_qing(qing)
      parent_node = build_or_find_parent_node_for_qing_group(qing.parent)
      if qing.multilevel?
        build_child(parent_node, "AnswerSet", form_item: qing)
      else
        parent_node
      end
    end

    def save(response)
      root = build_or_find_parent_node_for_qing_group(response.form.root_group)
      response.associate_tree(root)
      # TODO: We can remove the `validate: false` once various validations are
      # removed from the response model
      response.save(validate: false)
    end

    def answers?
      answer_groups.present?
    end

    private

    def build_or_find_parent_node_for_qing_group(qing_group)
      answer_groups[qing_group.id] ||=
        if qing_group.root?
          AnswerGroup.new(form_item: qing_group, new_rank: 0)
        else
          parent_node = build_or_find_parent_node_for_qing_group(qing_group.parent)
          if qing_group.repeatable?
            parent_node = build_child(parent_node, "AnswerGroupSet", form_item: qing_group)
          end
          build_child(parent_node, "AnswerGroup", form_item: qing_group)
        end
    end

    def build_child(response_node, type, **attribs)
      attribs[:new_rank] = response_node.children.size
      attribs[:type] = type
      response_node.children.build(attribs)
    end
  end
end
