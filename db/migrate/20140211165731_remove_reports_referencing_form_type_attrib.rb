class RemoveReportsReferencingFormTypeAttrib < ActiveRecord::Migration[4.2]
  def up
    # this attrib was never really used so these are likely dummy reports anyway
    # I checked and there are not very many
    res = execute("SELECT r.id FROM report_reports r INNER JOIN report_calculations c ON r.id=c.report_report_id WHERE c.attrib1_name = 'form_type'")
    ids = res.to_a.flatten
    unless ids.empty?
      transaction do
        execute("DELETE FROM report_calculations WHERE report_report_id IN (#{ids.join(',')})")
        execute("DELETE FROM report_option_set_choices WHERE report_report_id IN (#{ids.join(',')})")
        execute("DELETE FROM report_reports WHERE id IN (#{ids.join(',')})")
      end
    end
  end

  def down
  end
end
