# frozen_string_literal: true

desc "Populate Discourse_User_Id for Salesforce Contacts"

task "salesforce:populate_user_ids" => :environment do
  bulk_instance = DiscourseSalesforce::RestClient.bulk_api_instance
  instance = DiscourseSalesforce::RestClient.instance

  query = <<-SOQL_QUERY.strip
    SELECT Id, Email FROM Contact WHERE Discourse_User_Id__c = NULL
  SOQL_QUERY

  records = instance.query(query)
  emails = records.map { |record| record.Email }
  users = User.find_by_email(emails) 
  update_hash = records.map do |record|
    {
      Id: record.Id,
      Discourse_User_Id__c: User.find_by_email(record.Email)&.id
    }
  end
end
