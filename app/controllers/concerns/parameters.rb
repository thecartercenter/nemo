module Parameters
  extend ActiveSupport::Concern

  # return dynamic translations parameters
  def translation_params(params, *args)
    args.reduce([]) do |memo, arg|
      regex = /#{arg.to_s + '_' + '[a-z]+'}/
      memo << params.select { |key| regex.match(key.to_s) }.keys.first.to_sym
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
