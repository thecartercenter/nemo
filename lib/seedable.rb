module Seedable
  module ClassMethods
    def seed(key_field, attribs)
      key_val = attribs[key_field]
      # try to find the object
      if obj = send("find_by_#{key_field.to_s}", key_val)
        # update its attributes
        obj.attributes.each{|k,v| next if %w(id created_at updated_at).include?(k); obj.send("#{k}=", attribs[k.to_sym]) if attribs.keys.include?(k.to_sym)}
        # if it changed, say so and save it
        obj.save! if obj.changed?
        return obj
      else
        return create!(attribs)
      end
    end

    def unseed(key_field, key_value)
      if found = send("find_by_#{key_field}", key_value)
        found.destroy
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end