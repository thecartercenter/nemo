module Select2Helper
  def select2(value, options={})
    # invoke the select2 open action via JS
    execute_script("$('##{options[:from]}').select2('open')")

    # get the $results element from the Select2 data structure
    results_id = evaluate_script("$('##{options[:from]}').data('select2').$results.attr('id')")
    expect(results_id).to be_present

    # find the results element
    results = find_by_id(results_id)

    # wait for an LI to become available with the expected value, then click it
    expect(results.find('li')).to have_content(value)
    results.first('li', value).click

    # assert that the original select field was updated with the intended value
    select(value, options)
  end
end

RSpec.configure do |config|
  config.include Select2Helper, type: :feature
end
