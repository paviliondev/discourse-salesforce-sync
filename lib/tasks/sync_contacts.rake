# frozen_string_literal: true

desc "Sync Discourse Users with Salesforce Contacts"

task "salesforce:sync_contacts" => :environment do
  bulk_instance = DiscourseSalesforce::RestClient.bulk_api_instance
  updater = DiscourseSalesforce::ContactUpdater.new

  users = User.real
  users = users.where(approved: true) if SiteSetting.must_approve_users?

  contacts = users.map { |user| updater.build_contact(bulk_user: user) }
  result = bulk_instance.create("Contact", contacts)
  puts "result is: #{result.inspect}"
end
