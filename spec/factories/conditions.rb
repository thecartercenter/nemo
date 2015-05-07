FactoryGirl.define do
  factory :condition do
    op 'eq'
    value do
      ref_qing.has_options? ? nil : '1'
    end
    option do
      ref_qing.has_options? ? ref_qing.options.first : nil
    end
    mission {get_mission}
  end
end