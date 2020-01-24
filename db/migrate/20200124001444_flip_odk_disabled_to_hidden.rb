# frozen_string_literal: true

class FlipOdkDisabledToHidden < ActiveRecord::Migration[5.2]
  def change
    Questioning.all.each do |qing|
      # Preload/calculate questionings should be hidden (now that it exists) instead of disabled.
      if Odk::QingDecorator.decorate(qing).behind_the_scenes? && qing.disabled?
        puts qing.name
        qing.update!(disabled: false, hidden: true)
      end
    end
  end
end
