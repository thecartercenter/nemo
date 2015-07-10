class FormItem < ActiveRecord::Base; end
class QingGroup < FormItem; end
class Questioning < FormItem
  belongs_to(:form, :inverse_of => :questionings)
end
class Form < ActiveRecord::Base
  has_many(:questionings, :order => "rank", :autosave => true, :dependent => :destroy, :inverse_of => :form)
  belongs_to(:mission)
end

class MoveFormQuestioningsToRootGroup < ActiveRecord::Migration
  def up
    Form.all.each do |form|
      group = QingGroup.create(form_id: form.id, mission_id: form.mission_id)
      form.update_attribute(:root_id, group.id)
      # setting ancestry fields by hand so we can do them in bulk
      form.questionings.update_all(ancestry: group.id, ancestry_depth: 1)
    end
  end

  def down
  end
end
