module SearchesHelper
  def search_examples
    examples = I18n.t("search.examples.#{controller_name}", default: "")
    examples = safe_join(examples, "&nbsp;&nbsp;&nbsp;".html_safe) if examples.is_a?(Array)

    unless examples.blank?
      content_tag(:div, id: "search_examples") do
        t("common.example", count: examples.size).html_safe << "&nbsp;&nbsp;&nbsp;".html_safe << examples
      end
    end
  end

  def search_help_text_params
    if controller_name == 'questions'
      {question_types: QuestionType.all.map(&:human_name).join(', ')}
    else
      {}
    end
  end

  def all_forms
    all_of_type(Form)
  end

  def all_users
    all_of_type(User)
  end

  def all_groups
    all_of_type(UserGroup)
  end

  def all_of_type(model)
    items = model.all.map { |item| {name: item.name, id: item.id} }
    simple_smart_sort(items)
  end

  # Sorts a list of hashes by item key, using simple_smart_compare below.
  def simple_smart_sort(list, key = :name)
    list.sort do |x, y|
      x_value = x[key]
      y_value = y[key]
      simple_smart_compare(x_value, y_value)
    end
  end

  # Compares two strings alphabetically, ignoring case, properly understanding
  # numbers at the BEGINNING of the string only (for performance reasons).
  def simple_smart_compare(x_value, y_value)
    pattern = /(\d*)(.*)/
    x_match = x_value.downcase.match(pattern)
    y_match = y_value.downcase.match(pattern)

    # If both start with numbers, compare the numbers first.
    if !x_match[1].empty? && !y_match[1].empty?
      comparison = x_match[1].to_i <=> y_match[1].to_i
      return comparison unless comparison.zero?
      return x_match[2] <=> y_match[2]
    end

    # Otherwise compare the entire string.
    x_match[0] <=> y_match[0]
  end
end
