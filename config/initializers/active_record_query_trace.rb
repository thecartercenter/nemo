# frozen_string_literal: true

ActiveRecordQueryTrace.enabled = true if Rails.env.development? || Rails.env.test?
