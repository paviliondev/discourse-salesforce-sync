# frozen_string_literal: true

desc "Sync Discourse Users with Salesforce Contacts"

task "salesforce:sync_groups" => :environment do
  bulk_instance = DiscourseSalesforce::RestClient.bulk_api_instance
  updater = DiscourseSalesforce::GroupUpdater.new

  Group.all.find_in_batches do |group_array|
    group_records = group_array.map do |group|
      updater.build_group_record(bulk_group: group)
    end
    result = bulk_instance.create("Discourse_Membership__c", group_records)
    puts "result is: #{result.inspect}"
  end
end
