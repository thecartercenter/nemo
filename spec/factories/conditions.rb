FactoryGirl.define do
  factory :condition do
    op "eq"
    role "display"
    ref_qing { build(:questioning) }
    value { ref_qing.has_options? ? nil : '1' }
    option_node { ref_qing.has_options? ? ref_qing.option_set.c[0] : nil }
    mission { get_mission }
  end
end
