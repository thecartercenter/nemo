# frozen_string_literal: true

module Results
  # Builds (does not save) an answer tree based on answer data in a web response.
  class WebResponseParser
    TOP_LEVEL_PARAMS = %w[
      type
      id
      questioning_id
      value
      option_node_id
      datetime_value(1i)
      datetime_value(2i)
      datetime_value(3i)
      datetime_value(4i)
      datetime_value(5i)
      datetime_value(6i)
      date_value(1i)
      date_value(2i)
      date_value(3i)
      time_value(1i)
      time_value(2i)
      time_value(3i)
      time_value(4i)
      time_value(5i)
      time_value(6i)
      media_object_id
      choices_attributes
    ].freeze

    # replace choices_attributes top level param with a hash representing nested attributes
    PERMITTED_PARAMS = TOP_LEVEL_PARAMS.without(:choices_attributes)
      .append(choices_attributes: %w[id option_node_id checked]).freeze

    attr_reader :response

    def initialize(response)
      @response = response
    end

    # Expects ActionController::Parameters instance without required or permitted set, which is
    # a hash representing the structure of an answer heirarchy that comes with a web response.
    # Returns an unsaved answer tree object based on the hash
    def parse(web_answer_hash)
      children = web_answer_hash.fetch(:root, {}).fetch(:children, nil)
      return if children.blank?
      root = response.root_node || response.build_root_node(new_tree_node_attrs(web_answer_hash[:root], nil))
      parse_children(web_answer_hash[:root][:children], root)
      root
    end

    private

    def parse_children(web_hash_children, tree_parent)
      web_hash_children.each_pair do |_k, v|
        next if ignore_node?(v)
        child = update_or_add_node(v, tree_parent)
        child.response = response
        parse_children(v[:children], child) if v[:children]
      end
      tree_parent
    end

    def update_or_add_node(web_hash_node, tree_parent)
      id = web_hash_node[:id]
      raise SubmissionError, "Form item id invalid." unless item_in_mission?(web_hash_node[:questioning_id])

      # add
      if id.blank?
        tree_parent.children.build(new_tree_node_attrs(web_hash_node, tree_parent))
      else # update
        existing_node = tree_parent.children.select { |c| c.id == id }.first
        updatable_params = web_hash_node.permit(PERMITTED_PARAMS)
        merge_mission_id_for_choices(updatable_params)
        existing_node.update(updatable_params)
        existing_node.relevant = false if web_hash_node[:_relevant] == "false"
        existing_node._destroy = true if web_hash_node[:_destroy] == "true"
        existing_node
      end
    end

    def new_tree_node_attrs(web_hash_node, tree_parent)
      clean_params = web_hash_node.slice(*TOP_LEVEL_PARAMS).permit(PERMITTED_PARAMS)
      merge_mission_id_for_choices(clean_params)
      clean_params.merge(rank_attributes(tree_parent))
    end

    # Merge in the mission_id for all choices_attributes of the params
    # so the mission can be used later to scope things.
    def merge_mission_id_for_choices(clean_params)
      return unless clean_params.key?(:choices_attributes)

      clean_params[:choices_attributes].keys.each do |key|
        # Include mission_id FIRST so it can immediately be used in models to validate things.
        value = clean_params[:choices_attributes][key]
        clean_params[:choices_attributes][key] = {mission_id: @response.mission_id}.merge(value)
      end
    end

    def ignore_node?(web_hash_node)
      web_hash_node[:id].blank? &&
        (web_hash_node[:_relevant] == "false" || web_hash_node[:_destroy] == "true")
    end

    def rank_attributes(tree_parent)
      {new_rank: tree_parent.present? ? tree_parent.children.length : 0}
    end

    def item_in_mission?(questioning_id)
      form_items_in_mission[questioning_id].present?
    end

    def form_items_in_mission
      @form_items_in_mission ||=
        FormItem.where(mission_id: @response.mission_id).pluck(:id).index_by(&:itself)
    end
  end
end
