# frozen_string_literal: true

desc "Sync Discourse Users with Salesforce Contacts"

task "salesforce:sync_groups" => :environment do
  bulk_instance = DiscourseSalesforce::RestClient.bulk_api_instance
  updater = DiscourseSalesforce::GroupUpdater.new

  groups = Group.all
  group_records = groups.map do |group|
    updater.build_group(bulk_group: group)
  end
  result = bulk_instance.create("Discourse_Membership__c", group_records)
  puts "result is: #{result.inspect}"
end
