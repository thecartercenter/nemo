module Ancestry
  send :remove_const, :ANCESTRY_PATTERN
  const_set :ANCESTRY_PATTERN, /\A[\w\-]+(\/[\w\-]+)*\z/
end
