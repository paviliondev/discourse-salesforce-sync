# frozen_string_literal: true

# name: discourse-salesforce-sync
# about: A Discourse plugin to sync salesforce contacts with discourse users
# version: 0.1
# authors: Faizaan Gagan
# url: https://github.com/paviliondev/discourse-salesforce-sync

gem 'faraday_middleware', '1.0.0', require: true
gem 'restforce', '5.0.1', require: true

enabled_site_setting :discourse_salesforce_enabled

after_initialize do
  [
    "../lib/sf_rest_client.rb",
    "../lib/sf_contact_updater.rb",
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
end

on(:user_created) do |user|
  updater = DiscourseSalesforce::ContactUpdater.new(user)
  updater.create_or_update_record
end

on(:user_updated) do |user|
  updater = DiscourseSalesforce::ContactUpdater.new(user)
  updater.create_or_update_record
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
    DiscourseSalesforce::RestClient.reset!
  end
end
