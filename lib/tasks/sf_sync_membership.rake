# frozen_string_literal: true

desc "Sync Discourse Users with Salesforce Contacts"

task "salesforce:sync_membership" => :environment do
  bulk_instance = DiscourseSalesforce::RestClient.bulk_api_instance
  api_instance = DiscourseSalesforce::RestClient.instance
  group_map = get_group_map(api_instance)

  User.real.includes(:groups).find_in_batches do |users|
    users_map = get_users_map(api_instance, users.pluck(:id))
    membership_records = []

    users.each do |user|
      user_groups = user.groups
      user_groups.each do |group|
        membership_record = {
          Discourse_Membership__c: group_map[group.name],
          Contact__c: users_map[user.id],
        }
        membership_records << membership_record
      end
    end
    result = bulk_instance.create("Member__c", membership_records)
    puts "result is: #{result.inspect}"
  end
end

def get_group_map(instance)
  res = instance.query("select Id,Name from Discourse_Membership__c").pluck(:Name, :Id)
  hash = Hash[res]
end

def get_users_map(instance, user_ids)
  custom_field = SiteSetting.discourse_user_id_custom_field
  res = instance.query(
    "select Id,
     #{custom_field}
     from Contact
     WHERE #{custom_field} IN (#{user_ids.join(',')})"
  ).pluck(custom_field.to_sym, :Id)

  hash = Hash[res]
  hash.transform_keys(&:to_i)
end
