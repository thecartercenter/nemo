class Niller; def method_missing(*m); nil; end; end
def nn(x); x.nil? ? Niller.new : x; end