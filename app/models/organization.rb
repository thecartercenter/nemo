class Organization < ActiveRecord::Base
  include Replicable

  RESERVED_SUBDOMAINS = %w(admin api assets blog calendar demo developer developers docs files ftp git imap 
                           info lab mail manage mx pages pop sites smtp ssh ssl staging status support www)
  has_many :missions

=begin
Valid subdomain regex: 
 * must have a length no greater than 63.
 * must begin and end with an alpha-numeric (i.e. letters [A-Za-z] or digits [0-9]).
 * may contain hyphens (dashes), but may not begin or end with a hyphen.
=end

  validates :subdomain, presence: true,
                        uniqueness: true, 
                        exclusion: { in: RESERVED_SUBDOMAINS }, 
                        format: { with: /[A-Za-z0-9][A-Za-z0-9\-]{0,61}[A-Za-z0-9]|[A-Za-z0-9]/ }
  validates :name, presence: true, uniqueness: true
  
  before_save :format_subdomain

  private
    def format_subdomain
      subdomain.downcase!
    end

end
