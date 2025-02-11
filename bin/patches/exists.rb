unless Dir.respond_to?(:exists?)
  class << Dir
    alias_method :exists?, :exist?
  end
end

unless File.respond_to?(:exists?)
  class << File
    alias_method :exists?, :exist?
  end
end
