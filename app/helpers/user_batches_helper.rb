module UserBatchesHelper
  def get_line_errors(line)
    errors = []
    errors += line[:user].errors.full_messages if line[:user]
    errors << t('user_batch.bad_tokens', tokens: line[:bad_tokens].join(', ')) unless line[:bad_tokens].empty?
    truncate(errors.join(', '), length: 100)
  end
end