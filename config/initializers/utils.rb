# frozen_string_literal: true

class Niller
  def method_missing(*_m)
    nil
              end; end
def nn(x)
  x.nil? ? Niller.new : x
end
