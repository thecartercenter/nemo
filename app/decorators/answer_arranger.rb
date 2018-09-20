# # Creates OldAnswerNodes, OldAnswerInstances, and OldAnswerSets for a given response.
# # None of these are persisted to the database. Only Answer is persisted.
# #
# # Options:
# #   - placeholders - Whether to include blank answers for groups and questions.
# #       Can be :none, :except_repeats, or :all.
# #   - dont_load_answers - If true, does not load answers explicitly (and more efficiently) from the database.
# #       Instead, uses whatever `response.answers` returns.
# #
# # Answer object hierarchy:
# #
# # OldAnswerNode
# # - All answer data for a given FormItem within a specific OldAnswerInstance
# # - Has many OldAnswerInstances (if item is QingGroup) or one OldAnswerSet (if item is Qing)
# # OldAnswerInstance
# # - A set of OldAnswerNodes corresponding to one repeat instance of a QingGroup
# # - Has many OldAnswerNodes (at least one)
# # - Only repeat groups can have more than one OldAnswerInstance in their OldAnswerNode.
# # OldAnswerSet
# # - Set of one or more answers for a given question and instance
# # Answer
# # - A single answer
#
# class AnswerArranger
#   def initialize(response, options = {})
#     self.response = response
#     self.options = options
#     options[:placeholders] = :none unless options.has_key?(:placeholders)
#     options[:dont_load_answers] = false unless options.has_key?(:dont_load_answers)
#   end
#
#   # Returns a single OldAnswerInstance for the root group.
#   def build
#     # Prep
#     load_answers
#     scan_instance_nums
#
#     # Build the nodes
#     root_node = build_node(response.form.root_group, 1)
#
#     # Get the root instance, mark as root, and return
#     root_node.instances.first.tap do |root_instance|
#       root_instance.root = true
#     end
#   end
#
#   private
#
#   attr_accessor :response, :answers, :instance_nums, :options
#
#   # We do our own loading here to control order, eager loading, etc.
#   # (Unless instructed not to).
#   def load_answers
#     if options[:dont_load_answers]
#       self.answers = response.answers
#     else
#       # We eager load options, choices, and questionings since they are bound to be used.
#       # We order the answers so that the answers in answer sets will be in the proper rank order.
#       self.answers = response.answers
#         .includes(:form_item, :option, choices: :option)
#         .order(:questioning_id, :inst_num, :rank)
#     end
#   end
#
#   # Returns a new OldAnswerNode for the given FormItem and instance number.
#   # inst_num required only if item is a Questioning.
#   def build_node(item, inst_num)
#     if item.is_a?(QingGroup)
#       build_node_for_group(item)
#     else
#       build_node_for_questioning(item, inst_num)
#     end
#   end
#
#   def build_node_for_group(group)
#     OldAnswerNode.new(item: group).tap do |node|
#       nums = instance_nums[group.id] || []
#       no_answers_for_group = nums.empty?
#
#       if no_answers_for_group
#         if group.repeatable? && options[:placeholders] != :all || options[:placeholders] == :none
#           return nil
#         else
#           # If there are no instances and we've gotten this far, we still want to include one
#           # to illustrate that there is a group here but no answers in it.
#           nums = [1] if no_answers_for_group
#         end
#       end
#
#       # Build instances.
#       nums.each do |num|
#         instance = OldAnswerInstance.new(
#           num: num,
#           nodes: group.sorted_children.map { |c| build_node(c, num) }.compact
#         )
#         node.instances << instance
#       end
#
#       if group.repeatable? && options[:placeholders] == :all
#         node.placeholder_instance = OldAnswerInstance.new(
#           nodes: group.sorted_children.map { |c| build_node(c, :placeholder) }.compact,
#           placeholder: true
#         )
#       end
#     end
#   end
#
#   def build_node_for_questioning(item, inst_num)
#     OldAnswerNode.new(item: item).tap do |node|
#       answers = answers_for(item.id, inst_num)
#       if answers.blank? && (item.hidden? || options[:placeholders] == :none)
#         return nil
#       else
#         node.set = OldAnswerSet.new(questioning: item, answers: answers)
#       end
#     end
#   end
#
#   # Gets all inst_num values for all QingGroups on this Response.
#   # If a QingGroup has no answers at all, instance_nums[group_id] will be nil.
#   def scan_instance_nums
#     self.instance_nums = {}
#
#     # Root group always has one instance
#     instance_nums[response.form.root_id] = [1]
#
#     answers.each do |answer|
#       parent_id = answer.questioning.parent_id
#       instance_nums[parent_id] ||= []
#       instance_nums[parent_id] << answer.inst_num
#     end
#
#     instance_nums.each { |_, nums| nums.uniq!; nums.sort! }
#   end
#
#   def answers_for(qing_id, inst_num)
#     return [] if inst_num == :placeholder
#     return [] unless answer_table[qing_id]
#     answer_table[qing_id][inst_num]
#   end
#
#   def answer_table
#     return @answer_table if @answer_table
#     @answer_table = {}
#     by_qing_id = answers.group_by(&:questioning_id)
#     by_qing_id.each do |qing_id, answers_for_qing|
#       @answer_table[qing_id] = answers_for_qing.group_by(&:inst_num)
#     end
#     @answer_table
#   end
# end
