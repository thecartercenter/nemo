class UserSession < Authlogic::Session::Base
  # configuration here, see documentation for sub modules of Authlogic::Session
  logout_on_timeout(true)
  def to_key
      new_record? ? nil : [ self.send(self.class.primary_key) ]
  end
end