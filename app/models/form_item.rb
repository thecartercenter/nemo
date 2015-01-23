class FormItem < ActiveRecord::Base
  include MissionBased, FormVersionable, Replication::Replicable

  belongs_to(:form)

  before_create(:set_mission)

  has_ancestry cache_depth: true

  # Gets all leaves of the subtree headed by this FormItem, sorted.
  # These should all be Questionings.
  def sorted_leaves
    nodes = subtree.arrange(order: :rank)
    _sorted_leaves(nodes.values[0])
  end

  private

    # copy mission from question
    def set_mission
      self.mission = form.try(:mission)
    end

    def _sorted_leaves(nodes)
      nodes.map do |form_item, children|
        if form_item.is_a?(Questioning)
          form_item
        else
          _sorted_leaves(children)
        end
      end
    end

end
