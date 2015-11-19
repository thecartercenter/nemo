# Class responsible to reorganize the questions
# It's main concern is to separate a qing group that contains multilevel
# questionings into several groups. The idea here is to just remove the
# multilevel questioning from the group, since ODK doesn't show it correctly
# if it's a child of a group.
#
# Input:
# {
#   Qing => {},
#   QingGroup => {
#     Qing(1) => {},
#     Qing(2) => {},
#     Qing(3-multilevel) => {},
#     Qing(4) => {}
#   },
#   Qing => {},
# }
#
# Output:
# {
#   Qing => {},
#   QingGroup => {
#     QingGroupFragment => {
#       Qing(1) => {},
#       Qing(2) => {},
#     }
#     QingGroupFragment => {
#       Qing(3-multilevel) => {},
#     },
#     QingGroupFragment => {
#       Qing(4) => {}
#     },
#   }
#   Qing => {},
# }
class QingGroupOdkPartitioner
  attr_accessor :descendants, :organized_descendants

  def initialize(descendants)
    @descendants = descendants
    @organized_descendants = ActiveSupport::OrderedHash.new
  end

  def fragment
    @descendants.each do |key, value|
      if key.is_a? QingGroup
        split_qing_group_as_necessary(key, value)
      else
        store_regular_qing(key)
      end
    end
    @organized_descendants
  end

  private

  def split_qing_group_as_necessary(group, questionings)
    qing_group_divided = QingGroupFragment.new(group)

    questionings.each do |qing|
      qing_object = qing[0]

      if (qing_object.multi_level?)
        store_qing_group(group, qing_group_divided)

        # Start another group to separate these questionings from the old ones
        qing_group_divided = QingGroupFragment.new(group)
        add_qing_to_hash(qing_group_divided.children, qing_object)

        # store multilevel qing and start new group
        store_qing_group(group, qing_group_divided)
        qing_group_divided = QingGroupFragment.new(group)
      else
        add_qing_to_hash(qing_group_divided.children, qing_object)
      end
    end

    store_qing_group(group, qing_group_divided)
  end

  def store_qing_group(group, new_qing_group)
    @organized_descendants[group] ||= {}
    unless new_qing_group.children.empty?
      @organized_descendants[group][new_qing_group] = new_qing_group.children
    end
  end

  def store_multilevel_qing_outside_a_group(qing_object)
    store_regular_qing(qing_object)
  end

  def store_regular_qing(key)
    add_qing_to_hash(@organized_descendants, key)
  end

  # Since we are mimicking the original groups organization, we set
  # questionings as the key of the hash and no value for it. The views
  # are iterating through the keys later and just ignoring the values.
  def add_qing_to_hash(hash, key)
    hash[key] = ''
  end
end
