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
      attribs[:new_rank] = parent.children.size
      parent.children.build(attribs)
    end

    def build_or_find_parent_node_for(qing)
      qing_group = qing.parent
      answer_group = answer_group_for(qing_group) || build_answer_group(qing_group)
      if qing.multilevel?
        answer_group.children.build(type: "AnswerSet", form_item: qing, new_rank: answer_group.children.size)
      else
        answer_group
      end
    end

    def save(response)
      root = answer_group_for(response.form.root_group)
      response.associate_tree(root)
      # TODO: We can remove the `validate: false` once various validations are
      # removed from the response model
      response.save(validate: false)
    end

    def answers?
      answer_groups.present?
    end

    private

    def answer_group_for(qing_group)
      answer_groups[qing_group.id]
    end

    def build_answer_group(qing_group)
      answer_group =
        if qing_group.root?
          AnswerGroup.new(form_item: qing_group, new_rank: 0)
        else
          parent_response_node = answer_group_for(qing_group.parent) || build_answer_group(qing_group.parent)
          child_count = parent_response_node.children.size

          if qing_group.repeatable?
            parent_response_node = parent_response_node.children.build(
              type: "AnswerGroupSet", form_item: qing_group, new_rank: child_count
            )
            child_count = 0
          end

          parent_response_node.children.build(
            type: "AnswerGroup", form_item: qing_group, new_rank: child_count
          )
        end
      answer_groups[qing_group.id] = answer_group
    end
  end
end
