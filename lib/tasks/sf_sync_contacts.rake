# frozen_string_literal: true

desc "Sync Discourse Users with Salesforce Contacts"

task "salesforce:sync_contacts" => :environment do
  bulk_instance = DiscourseSalesforce::RestClient.bulk_api_instance
  api_instance = DiscourseSalesforce::RestClient.instance
  account_map = get_account_map(api_instance)

  User.real.find_in_batches do |user_array|
    contact_records = user_array.map do |u|
      first_name = nil
      last_name = u.username
      first_name, last_name = u.name.split(' ') if u.name.present?

      {
        FirstName: first_name,
        LastName: last_name,
        Email: u.email,
        AccountId: get_account_id(u.email, account_map),
        Discourse_User_Id__c: u.id,
      }
    end
    # pp contact_records
    result = bulk_instance.create("Contact", contact_records)
    puts "result is: #{result.inspect}"
  end
end

def get_account_id(email, account_map)
  account_name = DiscourseSalesforce::ContactUpdater.nhs_email_domain?(email) ?
    SiteSetting.discourse_salesforce_nhs_account_name :
    SiteSetting.discourse_salesforce_non_nhs_account_name

    account_map[account_name]
end

def get_account_map(instance)
  res = instance.query("select Id,Name from Account").pluck(:Name, :Id)
  Hash[res]
end
