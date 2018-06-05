require "spec_helper"

describe Odk::ResponseParser do
  #move XML submission specs over here one by one. For each one, change to use new answer hierarchy and expect_children. Then get it passing.

  let(:save_fixtures) { true }

  context "simple form" do

    it "should produce a simple tree from a form with three children" do
      #TODO: move to let statements
      filename = "simple_form_response.xml"
      form = create(:form, :published, :with_version, question_types: %w[text text text])
      values = %w[A B C]
      xml = prepare_odk_fixture(filename, form, values)
      files =  {xml_submission_file: StringIO.new(xml)}
      response = Response.new(form: form, mission: form.mission, user: create(:user))
      Odk::ResponseParser.new(response: response, files: files).populate_response
      answer_tree = response.root_node
      expect_children(answer_tree, %w[Answer Answer Answer], form.c.map(&:id), values)
    end
  end

  def expect_children(node, types, qing_ids, values)
    puts node.debug_tree
    children = node.children.sort_by(&:new_rank) #
    expect(children.map(&:type)).to eq types
    expect(children.map(&:questioning_id)).to eq qing_ids
    expect(children.map(&:new_rank)).to eq((1..children.size).to_a)
    if values.present? #QUESTION: this is not a guard clause. format ok?
      expect(children.map(&:value)).to eq values
    end
  end

  # TODO merge in helper w/ form_odk_rendering spec verson.
  # Accepts a fixture filename and form, and values array provided by a spec, and creates xml mimicking odk
  def prepare_odk_fixture(filename, form, values)
    items = form.preordered_items.map { |i| Odk::DecoratorFactory.decorate(i) }
    nodes = items.map(&:preordered_option_nodes).uniq.flatten
    xml = prepare_fixture("odk/responses/#{filename}",
      formname: [form.name],
      form: [form.id],
      formver: [form.code],
      itemcode: items.map(&:odk_code),
      itemqcode: items.map(&:code),
      optcode: nodes.map(&:odk_code),
      optsetid: items.map(&:option_set_id).compact.uniq,
      value: values)
    if save_fixtures
      dir = Rails.root.join("tmp", "odk_test_responses")
      FileUtils.mkdir_p(dir)
      File.open(dir.join(filename), "w") { |f| f.write(xml) }
    end
    xml
  end
end
