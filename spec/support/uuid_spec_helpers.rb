module UUIDSpecHelpers
  shared_context "factory helpers" do
    def factory_name(described_class)
      described_class.name.underscore.gsub("/", "_").to_sym
    end
  end

  # We are using this shared_examples in every model spec because it's helpful to catch oddities in some
  # models. e.g. `Setting` was filtering out attributes in admin mode so the uuid was
  # getting stripped before save.
  shared_examples "has a uuid" do
    include_context "factory helpers"

    let(:described_instance) { build(factory_name(described_class)) }

    it "generates a uuid when the record is created" do
      expect(described_instance.uuid).not_to be_empty
    end
  end
end
