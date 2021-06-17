desc "Sync Discourse Users with Salesforce Contacts"

task "salesforce:sync_contacts" => :environment do
  bulk_instance = DiscourseSalesforce::RestClient.bulk_api_instance
  User.real.find_in_batches do |user_array|
    contact_records = user_array.map do |u|
      first_name,last_name = u.name.split(' ')
      {
        FirstName: first_name,
        LastName: last_name || u.username,
        Email: u.email,
        AccountId: "0013G000008L4EJQA0",
        Discourse_User_Id__c: u.id,
      }
    end
    # pp contact_records
    result = bulk_instance.create("Contact", contact_records)
    puts "result is: #{result.inspect}"
  end
end
