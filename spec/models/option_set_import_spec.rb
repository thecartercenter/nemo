require 'rails_helper'

describe OptionSetImport do
  let(:mission) { get_mission }

  before do
    configatron.preferred_locale = :en
  end

  it 'should be able to import a simple option set' do
    name = "Simple"

    import = OptionSetImport.new(mission_id: mission.id, name: name, file: option_set_import_fixture("simple.xlsx"))
    import.run
    expect(import).to be_succeeded

    option_set = import.option_set

    expect_simple_option_set(option_set, name: name)
  end

  it 'should be able to import an option set in admin mode' do
    name = "Simple Standard"

    import = OptionSetImport.new(mission_id: nil, name: name, file: option_set_import_fixture("simple.xlsx"))
    import.run
    expect(import).to be_succeeded

    option_set = import.option_set

    expect_simple_option_set(option_set, name: name, standard: true)
  end

  it 'should be able to import a multi-level geographic option set' do
    name = "Multilevel Geographic"

    import = OptionSetImport.new(
      mission_id: mission.id,
      name: name,
      file: option_set_import_fixture("multilevel_geographic.xlsx")
    )
    import.run
    expect(import).to be_succeeded

    option_set = import.option_set

    expect(option_set).to have_attributes(
      name: name,
      level_count: 3,
      geographic?: true,
      allow_coordinates?: true)

    expect(option_set.level_names).to start_with(
      {'en' => 'Province'},
      {'en' => 'City/District'},
      {'en' => 'Commune/Territory'})

    # check the total and top-level option counts
    expect(option_set.total_options).to eq(321)
    expect(option_set.options).to have(26).items

    # make sure that the non-leaf options have no coordinates
    option_set.preordered_option_nodes.each do |node|
      if node.child_options.present?
        expect(node).to have_attributes(option: have_attributes(coordinates?: false))
      end
    end

    # verify the latitude and longitude of one of the options
    expect(option_set.all_options).to include(
      have_attributes(canonical_name: 'Aketi', latitude: 2.739529, longitude: 23.780851))
  end

  it 'should correctly report errors for invalid coordinate values' do
    name = "Invalid Geographic"

    import = OptionSetImport.new(
      mission_id: mission.id,
      name: name,
      file: option_set_import_fixture("invalid_geographic.xlsx")
    )
    import.run
    expect(import).not_to be_succeeded
  end

  it 'should successfully import csv option set' do
    name = "CSV Set"

    import = OptionSetImport.new(mission_id: mission.id, name: name, file: option_set_import_fixture("simple.csv"))
    import.run
    expect(import).to be_succeeded

    option_set = import.option_set

    expect_simple_option_set(option_set, name: "CSV Set")
  end

  private

  def expect_simple_option_set(option_set, name: "Simple", standard: false)
    expect(option_set).to have_attributes(
      name: name,
      geographic?: false,
      is_standard: standard)

    expect(option_set.levels).to be_nil
    expect(option_set.level_names).to include('en' => 'Province')

    expect(option_set.total_options).to eq(26)
    expect(option_set.all_options).to include(have_attributes(canonical_name: "Kinshasa"))
  end
end
