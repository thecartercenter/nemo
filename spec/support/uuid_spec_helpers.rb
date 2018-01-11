module UUIDSpecHelpers
  shared_context "factory helpers" do
    def factory_name(described_class)
      described_class.name.underscore.gsub("/", "_").to_sym
    end
  end
end
