class UpdateConditionOpsForI18n < ActiveRecord::Migration
  def up
    # converts all values of the op column of conditions by using the english translations
    hsh = I18n.t("conditions.operators").invert
    Condition.where("op IS NOT NULL").all.each do |c|
      c.op = hsh[c.op]
      c.save(:validate => false)
    end
  end

  def down
  end
end
