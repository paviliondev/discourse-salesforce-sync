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
  discourse_user_emails = UserEmail.where(primary: true, email: emails)

  update_hash = records.map do |record|
    {
      Id: record.Id,
      Discourse_User_Id__c: discourse_user_emails.find { |user_email| user_email.email == record.Email }&.user_id
    }
  end

  bulk_instance.update('Contact', update_hash)
end
