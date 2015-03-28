module Parameters
  extend ActiveSupport::Concern

  # return dynamic translations parameters
  def permit_translations(params, *args)
    return [] if params.blank?
    args.reduce([]) do |memo, arg|
      regex = /#{arg.to_s + '_' + '[a-z]+'}/
      keys = params.select { |key| regex.match(key.to_s) }.keys
      memo << keys.first.to_sym if keys.size > 0
      memo
    end
  end

  # build permitted array of attributes
  # for give recursive parameter and permitted structure
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
