class User < ActiveRecord::Base
  belongs_to(:role)
  belongs_to(:language)
  belongs_to(:location)
  before_validation(:clean_fields)
  before_destroy(:check_assoc)
  
  acts_as_authentic
  validates(:first_name, :presence => true)
  validates(:last_name, :presence => true)
  validates(:role_id, :presence => true)
  validates(:language_id, :presence => true)
  validate(:phone_length_or_empty)

  def self.select_options
    find(:all, :order => "first_name, last_name").collect{|u| [u.full_name, u.id]}
  end
  def self.sorted(page)
    paginate(:all, :order => "last_name, first_name", :page => page)
  end
  def self.default(params = {})
    User.new({:is_mobile_phone => true, :is_active => true, :language_id => Language.english.id}.merge(params))
  end
  def self.new_with_login_and_password(params)
    u = new(params)
    u.password = u.password_confirmation = random_password
    u.generate_login!
    u
  end
  def self.random_password(size = 8)
    charset = %w{2 3 4 6 7 9 a c d e f g h j k m n p q r t v w x y z}
    (0...size).map{charset.to_a[rand(charset.size)]}.join
  end
  def self.find_by_credentials(login, password)
    user = find_by_login(login)
    (user && user.valid_password?(password)) ? user : nil
  end
  def generate_login!
    base = "#{first_name[0,1]}#{last_name}".downcase.normalize
    try = 1
    until self.class.find_by_login(self.login = base + (try > 1 ? try.to_s : "")).nil?
      try += 1
    end
  end
  def phone_number
    phone.blank? ? "" : phone + (is_mobile_phone? ? " [m]" : "")
  end
  def deliver_intro!
    reset_perishable_token!
    Notifier.intro(self).deliver
  end
  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.password_reset_instructions(self).deliver  
  end
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def is_observer?; role ? role.is_observer? : false; end
  def is_program_staff?; role ? role.is_program_staff? : false; end
  
  private
    def clean_fields
      self.phone = "+" + phone.gsub(/[^0-9]/, "") unless phone.blank?
    end
    
    def phone_length_or_empty
      errors.add(:phone, "must be at least 9 digits.") unless phone.blank? || phone.size >= 10
    end
    
    def check_assoc
    end
end
