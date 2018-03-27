module FeatureSpecHelpers
  def login(user)
    visit "/test-login?user_id=#{user.id}"
    expect(page).to have_content("Profile:")
  end

  def fill_in_ckeditor(locator, opts)
    wait_for_ckeditor(locator)

    content = opts.fetch(:with).to_json
    page.execute_script <<-SCRIPT
      CKEDITOR.instances['#{locator}'].setData(#{content});
      $('textarea##{locator}').text(#{content});

      // Need to fire this manually for poltergeist for some reason.
      CKEDITOR.instances['#{locator}'].fire('change');
    SCRIPT
  end

  # Fills in a token input *JS MUST BE ENABLED
  # EX: fill_in_token_input 'custodian_id', with: 'M', pick: 'Market'
  # EX: fill_in_token_input 'custodian_id', with: 'A', pick: 1
  #
  # @param id [String] id of the original text input that has been replaced by the tokenInput
  # @option with [String] *required
  # @option pick [Symbol, String, Integer] result to pick, defaults to first result
  # @option dont_pick [Boolean] If true, doesn't pick anything, just fills in the box and leaves the resulting
  #   suggestions open for inspection.
  def fill_in_token_input(id, options)
    # Generate selectors for key elements
    # The tokenInput-generated visible text field
    text_input_selector = "#token-input-#{id}"
    # The <ul> tag containing the selected tokens and visible test input
    token_input_list_selector = ".token-input-list-elmo:has(li #{text_input_selector})"
    # The result list
    result_list_selector = ".token-input-selected-dropdown-item-elmo"

    # Trigger clicking on the token input
    page.driver.execute_script("$('#{token_input_list_selector}').trigger('click');")
    # Wait until the 'Type in a search term' box appears
    page.has_xpath? "//div[contains(text(),'Type an option name')]"

    # Fill in the visible text box
    page.driver.execute_script("$('#{text_input_selector}').val('#{options[:with]}');")
    # Triggering keydown initiates the ajax request within tokenInput
    page.driver.execute_script("$('#{text_input_selector}').trigger('keydown');")
    # The result_list_selector will show when the AJAX request is complete
    expect(page).to have_selector(result_list_selector, visible: true)

    # Pick the result
    unless options[:dont_pick]
      if options[:pick]
        textual_numbers = [:first, :second, :third, :fourth, :fifth]
        if index = textual_numbers.index(options[:pick])
          selector = ":nth-child(#{index+1})"
        elsif options[:pick].class == String
          selector = ":contains(\"#{options[:pick]}\")"
        elsif options[:pick].class == Integer
          selector = ":nth-child(#{options[:pick]})"
        end
      else
        selector = ':first-child'
      end

      page.driver.execute_script("$('#{result_list_selector}#{selector}').trigger('mousedown');")

      # A missing result_list_selector signifies that the selection has been made
      page.has_css?(result_list_selector)
    end
  end

  # Focus on a tokenInput
  # @param id [String] *required
  #
  def focus_on_token_input(id)
    page.driver.execute_script("$('##{id}').siblings('ul').trigger('click')")
    sleep(0.1)
  end

  # Get the JS array of tokens in a tokenInput instance
  # @param id [String] *required
  #
  def get_token_input(id)
    page.driver.execute_script("$('##{id}').tokenInput('get')")
  end

  # Clears a tokenInput
  # @param id [String] *required
  #
  def clear_token_input(id, options={})
    page.driver.execute_script("$('##{id}').tokenInput('clear', #{options.to_json})")
    sleep(0.1)
  end

  def wait_modal_to_be_visible(modal_selector='.modal-dialog')
    expect(page).to have_selector(modal_selector, visible: true)
  end

  def wait_modal_to_hide(modal_selector='.modal-dialog')
    expect(page).to have_selector(modal_selector, visible: false)
  end

  shared_examples :form_logic do
    def select_question(code)
      find('select[name*="\\[ref_qing_id\\]"]').select(code)
      wait_for_ajax # Changing the question triggers an ajax call (for now)
    end

    def expect_selected_question(qing)
      select = find('select[name*="\\[ref_qing_id\\]"]')
      expect(page).to have_select(select[:name], selected: "#{qing.full_dotted_rank}. #{qing.code}")
    end

    def select_operator(op)
      find('select[name*="\\[op\\]"]').select(op)
    end

    def expect_selected_operator(op)
      select = find('select[name*="\\[op\\]"]')
      expect(page).to have_select(select[:name], selected: op)
    end

    def select_values(*values)
      selects = all('select[name*="\\[option_node_ids\\]"]')
      values.each_with_index do |value, i|
        selects[i].select(value)
      end
    end

    def expect_selected_values(*values)
      selects = all('select[name*="\\[option_node_ids\\]"]')
      expect(selects.size).to eq values.size
      selects.each_with_index do |select, i|
        expect(page).to have_select(select[:name], selected: values[i])
      end
    end

    def fill_in_value(value)
      find('input[name*="\\[value\\]"]').set(value)
    end

    def expect_filled_in_value(value)
      input = find('input[name*="\\[value\\]"]')
      expect(page).to have_field(input[:name], with: value)
    end

    def click_add_condition
      find("a", text: "Add Condition").click
    end

    def click_add_rule
      find("a", text: "Add Rule").click
    end

    def click_delete_link
      find(".fa-close", match: :first).click
    end
  end

  private

  def wait_for_ckeditor(locator)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until ckeditor_ready? locator
    end
  end

  def ckeditor_ready?(locator)
    page.evaluate_script "CKEDITOR.instances['#{locator}'].instanceReady;"
  end
end
