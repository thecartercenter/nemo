# Serializes form items for cases where they are targets of conditional logic, like ref_qing or dest_item.
class TargetFormItemSerializer < ActiveModel::Serializer
  attributes :id, :code, :rank, :full_dotted_rank
end
