module SettingsHelper
  def sms_adapters(options={})
    return Sms::Adapters::Factory.products(options)
  end
end
