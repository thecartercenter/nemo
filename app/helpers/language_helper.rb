module LanguageHelper
  # finds the english name of the language with the given code (e.g. 'French' for 'fr')
  # tries to use the translated locale name if it exists, otherwise use english language name from the iso639 gem
  # returns code itself if code not found
  def language_name(code)
    if configatron.full_locales.include?(code)
      I18n.t(:locale_name, :locale => code)
    else
      (entry = ISO_639.find(code.to_s)) ? entry.english_name : code.to_s
    end
  end
end
