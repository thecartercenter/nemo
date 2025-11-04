class UpdateConditionOpsForI18n < ActiveRecord::Migration[4.2]
  def up
    # converts all values of the op column of conditions by using the english translations
    hsh = I18n.t("condition.operators").invert
    Condition.where.not(op: nil).all.each do |c|
      c.op = hsh[c.op]
      c.save(validate: false)
    end
  end

  def down
  end
end
