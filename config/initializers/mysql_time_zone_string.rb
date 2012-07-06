module ActiveSupport
  class TimeZone
    def mysql_name
      self.class::MAPPING[name]
    end
  end
end