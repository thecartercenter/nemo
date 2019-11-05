# frozen_string_literal: true

shared_context "ability" do
  shared_examples_for "has specified abilities" do
    it "permits" do
      permitted.each { |op| expect(ability).to be_able_to(op, object) }
    end

    it "forbids" do
      (all - permitted).each { |op| expect(ability).not_to be_able_to(op, object) }
    end
  end
end
