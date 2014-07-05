class Organization < ActiveRecord::Base
  include Replicable
  #TODO: do we need to includeMissionBased ?



  RESERVED_SUBDOMAINS = %w(admin api assets blog calendar demo developer developers docs files ftp 
                           git imap lab mail manage mx pages pop sites smtp ssh ssl staging status support www)
  has_many :missions

  validates :name,         uniqueness: true, presence: true
  validates :compact_name, uniqueness: true, exclusion: { in: RESERVED_SUBDOMAINS }

  before_validation :create_compact_name  

  private
    def create_compact_name
      self.compact_name = name.gsub(/\s|&|\||\'|\"/, "").downcase unless compact_name.present?
      return true
    end

end
