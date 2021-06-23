# frozen_string_literal: true

# name: discourse-salesforce-sync
# about: A Discourse plugin to sync salesforce contacts with discourse users
# version: 0.1
# authors: Faizaan Gagan
# url: https://github.com/paviliondev/discourse-salesforce-sync

gem 'faraday_middleware', '1.0.0', require: true
gem 'restforce', '5.0.1', require: true
gem 'xml-simple', '1.1.8', require: false
gem 'salesforce_bulk_api', '1.0.0', require: true

enabled_site_setting :discourse_salesforce_enabled

after_initialize do
  [
    "../lib/sf_rest_client.rb",
    "../lib/sf_contact_updater.rb",
    "../lib/sf_group_membership_manager.rb",
    "../jobs/sf_update_contact_record.rb",
    "../jobs/sf_update_group_membership.rb"
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
end

on(:user_created) do |user|
  ::Jobs.enqueue(
    :sf_update_contact_record,
    user_id: user.id,
  )
end

on(:user_updated) do |user|
  ::Jobs.enqueue(
    :sf_update_contact_record,
    user_id: user.id,
  )
end

on(:site_setting_changed) do |name, _, _|
  client_settings = %i{
    discourse_salesforce_client_id
    discourse_salesforce_client_secret
    discourse_salesforce_username
    discourse_salesforce_password
    discourse_salesforce_host
  }

  if (client_settings.include?(name))
    begin
      DiscourseSalesforce::RestClient.reset!
      DiscourseSalesforce::RestClient.reset_bulk_api_instance!
    rescue Restforce::AuthenticationError
      #TODO: notify admins about the credentials not working
    end
  end
end

on(:user_added_to_group) do |user, group|
  ::Jobs.enqueue(
    :sf_update_group_membership,
    user_id: user.id,
    group_id: group.id,
    action: "add"
  )
end

on(:user_removed_from_group) do |user, group|
  ::Jobs.enqueue(
    :sf_update_group_membership,
    user_id: user.id,
    group_id: group.id,
    action: "remove"
  )
end
