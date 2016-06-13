# We need to override the translation helper here
# in order to fix cases where a translation within an
# HTML element will try to insert a <span>
# it replaces the span with the translation key

module TranslationHelper
  def translate(key, options={})
    super(key, options.merge(raise: true))
  rescue I18n::MissingTranslationData
    key.to_s
  end
  alias :t :translate
end
