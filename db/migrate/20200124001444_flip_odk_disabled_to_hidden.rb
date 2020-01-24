# frozen_string_literal: true

class FlipOdkDisabledToHidden < ActiveRecord::Migration[5.2]
  def change
    Questioning.all.each do |qing|
      reversible do |dir|
        dir.up do
          # Preload/calculate qings should be hidden instead of disabled (now that they're different).
          if behind_the_scenes?(qing) && qing.disabled?
            qing.update!(disabled: false, hidden: true)
          end
        end

        dir.down do
          if behind_the_scenes?(qing) && qing.hidden?
            qing.update!(disabled: true, hidden: false)
          end
        end
      end
    end
  end

  def behind_the_scenes?(qing)
    qing.metadata_type == "formstart" || qing.metadata_type == "formend" || qing.default.present?
  end
end
