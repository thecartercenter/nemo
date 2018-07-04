class FormItem < ActiveRecord::Base; end
class QingGroup < FormItem; end
class Questioning < FormItem
  belongs_to(:form, inverse_of: :questionings)
end

class Form < ActiveRecord::Base
  if Rails::VERSION::MAJOR >= 4
    has_many(:questionings, -> { order(:rank) }, autosave: true, dependent: :destroy, inverse_of: :form)
  else
    has_many(:questionings, order: "rank", autosave: true, dependent: :destroy, inverse_of: :form)
  end
  belongs_to(:mission)
end

class MoveFormQuestioningsToRootGroup < ActiveRecord::Migration[4.2]
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
