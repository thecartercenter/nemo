# frozen_string_literal: true

shared_context "trumbowyg" do
  def fill_in_trumbowyg(selector, opts)
    wait_for_trumbowyg(selector)
    content = opts.fetch(:with).to_json
    page.execute_script(<<-SCRIPT)
      $('#{selector}').trumbowyg('html', #{content});
    SCRIPT
  end

  private

  def wait_for_trumbowyg(selector)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until trumbowyg_ready?(selector)
    end
  end

  def trumbowyg_ready?(selector)
    page.evaluate_script("$('#{selector}').trumbowyg('html') !== false")
  end
end
