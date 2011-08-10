class Smser
  def self.deliver(recips, msg)
    adapter = Kernel.const_get(configatron.outgoing_sms_adapter)
    adapter.deliver(recips.collect{|r| r.phone.gsub(/[^\d]/, "")}, msg)
  end
end