# frozen_string_literal: true

desc "Sync Discourse Users with Salesforce Contacts"

task "salesforce:sync_memberships" => :environment do
  bulk_instance = DiscourseSalesforce::RestClient.bulk_api_instance
  api_instance = DiscourseSalesforce::RestClient.instance
  group_map = get_group_map(api_instance)

  users = User.real
  users = users.where(approved: true) if SiteSetting.must_approve_users?

  users_list = users.includes(:groups).all
  users_map = get_users_map(api_instance, users_list.pluck(:id))
  manager = ::DiscourseSalesforce::GroupMembershipManager.new
  membership_records = []

  users_list.each do |user|
    user_groups = user.groups
    user_groups.each do |group|
      membership_records << manager.build_membership(group_map[group.name], users_map[user.id])
    end
  end

  result = bulk_instance.create("Member__c", membership_records)
  puts "result is: #{result.inspect}"
end

def get_group_map(instance)
  res = instance.query("select Id,Name from Discourse_Membership__c").pluck(:Name, :Id)
  hash = Hash[res]
end

def get_users_map(instance, user_ids)
  custom_field = SiteSetting.discourse_salesforce_discourse_user_id_custom_field
  res_final = []

  user_ids.in_groups_of(1000, false) do |user_ids_subset|
    res = instance.query(
      "select Id,
       #{custom_field}
       from Contact
       WHERE #{custom_field} IN (#{user_ids_subset.join(',')})"
    ).pluck(custom_field.to_sym, :Id)

    res_final.push(*res)
  end

  hash = Hash[res_final]
  hash.transform_keys(&:to_i)
end
