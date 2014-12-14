class QingGroup < FormItem
  include MissionBased, FormVersionable, Standardizable, Replicable

  belongs_to(:form, :inverse_of => :questionings)
  belongs_to(:question, :autosave => true, :inverse_of => :questionings)
  has_many(:answers, :dependent => :destroy, :inverse_of => :questioning)
  has_one(:condition, :autosave => true, :dependent => :destroy, :inverse_of => :questioning)
  has_many(:referring_conditions, :class_name => "Condition", :foreign_key => "ref_qing_id", :dependent => :destroy, :inverse_of => :ref_qing)
  has_many(:standard_form_reports, class_name: 'Report::StandardFormReport', foreign_key: 'disagg_qing_id', dependent: :nullify)

end
