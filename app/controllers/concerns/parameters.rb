module Parameters
  extend ActiveSupport::Concern

  def translation_params(params, *args)
    args.reduce([]) do |memo, arg|
      regex = /#{arg.to_s + '_' + '[a-z]+'}/
      memo << params.select { |key| regex.match(key.to_s) }.keys.first.to_sym
    end
  end
end