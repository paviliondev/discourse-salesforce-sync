desc "Sync Discourse Users with Salesforce Contacts"

task "salesforce:sync_groups" => :environment do
  bulk_instance = DiscourseSalesforce::RestClient.bulk_api_instance
  Group.find_in_batches do |group_array|
    group_records = group_array.map do |group|
     {
       Name: group.name,
       Discourse_Membership_Long_Name__c: group.full_name
     }
    end
    result = bulk_instance.create("Discourse_Membership__c", group_records)
    puts "result is: #{result.inspect}"
  end
end
