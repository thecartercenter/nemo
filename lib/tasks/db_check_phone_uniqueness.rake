# frozen_string_literal: true

namespace :db do
  desc "Ensures all phone numbers in the database are unique."
  task check_phone_uniqueness: :environment do
    # build a big has of phone => [users]
    phone_hash = {}
    User.all.each do |u|
      # cleanup any blank phone numbers
      u.phone = nil if u.phone == ""
      u.phone2 = nil if u.phone2 == ""
      u.save(validate: false) if u.changed?

      # add to hash
      (phone_hash[u.phone] ||= []) << u if u.phone.present?
      (phone_hash[u.phone2] ||= []) << u if u.phone2.present?
    end

    # if there are any hash values with more than one entry, add to fault list
    faults = []
    phone_hash.each_pair do |phone, users|
      next unless users.size > 1
      names = users.map(&:name).join(", ")
      # if requested to fix, fix and report
      if ENV["fix"] == "true"
        users[1..].each do |u|
          u.phone = nil if u.phone == phone
          u.phone2 = nil if u.phone2 == phone
          u.save(validate: false)
          puts "Removed phone number #{phone} from #{u.name}"
        end
      # else just report
      else
        faults << "Phone number #{phone} is assigned to #{names}"
      end
    end

    # print out appropriate info
    if faults.empty?
      puts "Congrats, all phone numbers are unique."
    else
      puts "WARNING: The following phone numbers are assigned to multiple users."
      puts "These users will not be able to be edited until their phone numbers are made unique."
      puts faults.join("\n")
      puts "You can re-run this script as rake db:check_phone_uniqueness " \
        "fix=true to remove any duplicate numbers from all but the first user"
    end
  end
end
