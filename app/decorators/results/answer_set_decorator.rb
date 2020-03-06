# frozen_string_literal: true

module Results
  class AnswerSetDecorator < ResponseNodeDecorator
    def classes
      ["answer-set", "form-field", "qtype-select-one", mode_class, error_class].compact.join(" ")
    end

    def select_tag(answer, level_context)
      name = level_context.input_name(:option_node_id)
      h.select_tag(name, select_options(answer, level_context),
        include_blank: true, class: "form-control")
    end

    def level_name(level_context)
      option_set.level_name_for_depth(level_context.index + 1)
    end

    private

    def select_options(answer, level_context)
      h.options_from_collection_for_select(option_nodes(level_context),
        "id", "name", answer&.option_node_id)
    end

    def option_nodes(level_context)
      option_node_path.nodes_for_depth(level_context.index + 1)
    end
  end
end
