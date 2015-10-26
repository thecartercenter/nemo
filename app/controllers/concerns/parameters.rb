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

  # Returns an array of permitted param keys that tracks the structure of the given params.
  def permit_children(params, options)
    key = options[:key]
    permitted = options[:permitted]
    if params[key].present?
      params[key].map do |child|
        if child[key].present? && child[key] != 'NONE'
          permitted + [{ key => permit_children(child, options) }]
        else
          permitted + [key]
        end
      end
    end
  end
end
