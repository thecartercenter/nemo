module Parameters
  extend ActiveSupport::Concern

  # return dynamic translations parameters
  def permit_translations(params, *prefixes)
    return [] if prefixes.empty? || params.blank?
    regex = /\A(#{prefixes.join('|')})_[a-z]{2}\z/
    whitelisted = []
    params.each do |key, value|
      if key =~ regex && value.is_a?(String)
        whitelisted << key
      elsif value.is_a?(Hash) # Recurse
        whitelisted << { key => permit_translations(value, *prefixes) }
      end
    end
    whitelisted
  end

  # build permitted array of attributes
  # for given recursive parameter and permitted structure
  def permit_children(params, rec_param, permitted)
    result = []
    _permit_children(params, rec_param, permitted, result)
    result
  end

  private
    def _permit_children(params, key, permitted, result)
      result.push(*permitted)
      params = params[0]
      return result if params.blank? || params[key].blank?

      result << Hash[key, []]
      _permit_children(params[key], key, permitted, result.last[key])
    end
end
