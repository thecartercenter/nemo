# frozen_string_literal: true

class Object
  # Nice syntactic sugar. https://jsarbada.wordpress.com/2019/02/05/destructuring-with-ruby/
  def values_at(*attributes)
    attributes.map { |attribute| send(attribute) }
  end
end
