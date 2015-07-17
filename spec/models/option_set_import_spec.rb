require 'spec_helper'

describe OptionSetImport do
  let(:mission) { get_mission }

  it 'should be able to import a simple option set' do
    name = "Simple"

    import = OptionSetImport.new(mission_id: mission.id, name: name, file: fixture("simple.xlsx"))

    succeeded = import.create_option_set
    expect(succeeded).to be_truthy

    option_set = import.option_set

    expect(option_set).to have_attributes(
      name: name,
      geographic?: false)

    expect(option_set.levels).to be_nil
    expect(option_set.level_names).to include('en' => 'Province')

    expect(option_set.total_options).to eq(26)
    expect(option_set.all_options).to include(have_attributes(canonical_name: "Kinshasa"))
  end

  private

    def fixture(name)
      File.expand_path("../../fixtures/option_set_imports/#{name}", __FILE__)
    end
end
