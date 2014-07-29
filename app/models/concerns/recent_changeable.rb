module RecentChangeable
  extend ActiveSupport::Concern

  included do
    serialize :recent_changes
    before_save :maintain_recent_changes
  end

  def recent_change_for(attrib_name)
    return nil if recent_changes.nil?
    recent_changes[attrib_name.to_s]
  end

  private
    def maintain_recent_changes
      if capturing_changes?
        self.recent_changes ||= {}
        self.recent_changes.merge!(changes.except('recent_changes'))
      end
      return true
    end

    def capturing_changes?
      Thread.current[:elmo_capturing_changes?] && respond_to?(:recent_changes)
    end

    def clear_recent_changes!
      update_column(:recent_changes, nil) if respond_to?(:recent_changes)
    end
end
