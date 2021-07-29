# frozen_string_literal: true

module ODK
  class SubqingDecorator < BaseDecorator
    delegate_all

    delegate :ancestors, :decorated_option_set, :select_one_with_external_csv?, :self_and_ancestor_ids,
      :has_options?, :option_set, :media_prompt?, :question, :top_level?, :hint, :path_from_ancestor,
      to: :decorated_questioning

    # If options[:previous] is true, returns the code for the
    # immediately previous subqing (multilevel only).
    def odk_code(options = {})
      CodeMapper.instance.code_for_item(object, options)
    end

    def absolute_xpath
      (decorate_collection(ancestors.to_a) << self).map(&:odk_code).join("/")
    end

    def input_tag(render_mode:, xpath_prefix:)
      opts = {}
      opts[:ref] = [xpath_prefix, xpath_suffix(render_mode)].compact.join("/")
      opts[:rows] = 5 if qtype.name == "long_text"
      opts[:appearance] = appearance(render_mode)
      opts[:mediatype] = media_type if qtype.multimedia?
      opts[:query] = external_csv_itemset_query
      content_tag(tagname, opts) do
        [label_tag(render_mode), hint_tag(render_mode), items_or_itemset].compact.reduce(:<<)
      end
    end

    def required?
      questioning.required? && questioning.visible? &&
        (questioning.all_levels_required? || first_rank?)
    end

    private

    def decorated_questioning
      @decorated_questioning ||= decorate(object.questioning)
    end

    def xpath_suffix(render_mode)
      if render_mode == :label_row
        # We can't bind to the question's node here or, if the question is required,
        # we won't be allowed to proceed since it won't be possible to fill in the question.
        # Also, this question will appear again in a regular row so it would be weird
        # to link it to the same instance node twice.
        # Instead we use a special bind tag that only gets included if we're in grid mode
        # (see the labels_bind_tag method in QingGroupDecorator).
        "labels"
      else
        odk_code
      end
    end

    def label_tag(render_mode)
      return if render_mode == :label_row
      tag(:label, ref: "jr:itext('#{odk_code}:label')")
    end

    def hint_tag(render_mode)
      return if render_mode != :normal
      tag(:hint, ref: "jr:itext('#{odk_code}:hint')")
    end

    def items_or_itemset
      return if !has_options? || use_external_csv_itemset_query?
      rank == 1 ? top_level_items : itemset
    end

    def top_level_items
      option_set.sorted_children.map do |ch|
        content_tag(:item) do
          code = CodeMapper.instance.code_for_item(ch)
          tag(:label, ref: "jr:itext('#{code}')") <<
            content_tag(:value, code)
        end
      end.reduce(:<<)
    end

    def itemset
      instance_id = decorated_option_set.instance_id_for_depth(rank)
      nodeset_ref = "instance('#{instance_id}')/root/item[parentId=#{path_to_prev_subqing}]"
      content_tag(:itemset, nodeset: nodeset_ref) do
        tag(:label, ref: "jr:itext(itextId)") <<
          tag(:value, ref: "itextId")
      end
    end

    def external_csv_itemset_query
      return unless use_external_csv_itemset_query?
      # In external csv method, we use the same instance ID (just the option set odk_code) for all levels.
      # We use parent_id here for historical reasons.
      "instance('#{decorated_option_set.odk_code}')/root/item[parent_id=#{path_to_prev_subqing}]"
    end

    def path_to_prev_subqing
      "current()/../#{decorated_questioning.subqings[rank - 2].odk_code}"
    end

    def tagname
      if qtype.name == "select_one" && (first_rank? || !select_one_with_external_csv?)
        :select1
      elsif qtype.name == "select_multiple"
        :select
      elsif qtype.multimedia?
        :upload
      else
        :input
      end
    end

    def appearance(render_mode) # rubocop:disable Metrics/CyclomaticComplexity # Case statements OK
      return "label" if render_mode == :label_row
      return "list-nolabel" unless render_mode == :normal

      case qtype.name
      when "annotated_image" then "annotate"
      when "sketch" then "draw"
      when "signature" then "signature"
      when "counter" then counter_appearance
      end
    end

    def media_type
      case qtype.name
      when "image", "annotated_image", "sketch", "signature" then "image/*"
      when "audio" then "audio/*"
      when "video" then "video/*"
      end
    end

    def counter_appearance
      params = ActiveSupport::OrderedHash.new
      params[:form_id] = "'#{questioning.form_id}'"
      params[:form_name] = "'#{questioning.form_name}'"
      params[:question_id] = "'#{CodeMapper.instance.code_for_item(questioning)}'"
      # Code instead of title because it's not locale dependent.
      params[:question_name] = "'#{questioning.code}'"
      params[:increment] = "true()" if questioning.auto_increment?
      str = params.map { |k, v| "#{k}=#{v}" }.join(", ")

      # This is not HTML and won't be run in a browser so output safety isn't an issue.
      "ex:org.opendatakit.counter(#{str})".html_safe # rubocop:disable Rails/OutputSafety
    end

    def use_external_csv_itemset_query?
      select_one_with_external_csv? && !first_rank?
    end
  end
end
