# frozen_string_literal: true

class FlipOdkDisabledToHidden < ActiveRecord::Migration[5.2]
  def change
    Questioning.all.each do |qing|
      reversible do |dir|
        dir.up do
          # Preload/calculate qings should be hidden instead of disabled (now that they're different).
          qing.update!(disabled: false, hidden: true) if behind_the_scenes?(qing) && qing.disabled?
        end

        dir.down do
          qing.update!(disabled: true, hidden: false) if behind_the_scenes?(qing) && qing.hidden?
        end
      end
    end
  end

  def behind_the_scenes?(qing)
    qing.metadata_type == "formstart" || qing.metadata_type == "formend" || qing.default.present?
  end
end
