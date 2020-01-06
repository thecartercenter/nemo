# frozen_string_literal: true

# monkey-patch ActiveJob::Base to have a provider_job_id (to be added in Rails 5)
unless ActiveJob::Base.instance_methods.include?(:provider_job_id)
  ActiveJob::Base.class_eval do
    attr_accessor :provider_job_id

    around_enqueue do |_, block|
      block.call.tap do |provider_job|
        self.provider_job_id = provider_job.try(:id)
      end
    end
  end
end
