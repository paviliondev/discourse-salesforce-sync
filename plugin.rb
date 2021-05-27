# frozen_string_literal: true

# name: discourse-salesforce-sync
# about: A Discourse plugin to sync salesforce contacts with discourse users
# version: 0.1
# authors: Faizaan Gagan
# url: https://github.com/paviliondev/discourse-salesforce-sync

gem 'faraday_middleware', '1.0.0', require: true
gem 'restforce', '5.0.1', require: true

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
