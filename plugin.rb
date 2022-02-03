# frozen_string_literal: true

# name: discourse-salesforce-sync
# about: A Discourse plugin to sync salesforce contacts with discourse users
# version: 0.1
# authors: Faizaan Gagan
# url: https://github.com/paviliondev/discourse-salesforce-sync

gem 'faraday_middleware', '1.0.0', require: true
gem 'restforce', '5.2.1', require: true
gem 'xml-simple', '1.1.8', require: false
gem 'salesforce_bulk_api', '1.0.0', require: true

enabled_site_setting :discourse_salesforce_enabled

after_initialize do
  [
    "../lib/discourse_salesforce/engine.rb",
    "../lib/discourse_salesforce/rest_client.rb",
    "../lib/discourse_salesforce/contact_updater.rb",
    "../lib/discourse_salesforce/group_updater.rb",
    "../lib/discourse_salesforce/group_membership_manager.rb",
    "../lib/discourse_salesforce/notifier.rb",
    "../jobs/update_contact_record.rb",
    "../jobs/update_group.rb",
    "../jobs/update_group_membership.rb",
    "../jobs/data_integrity_check.rb"
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  module DiscourseSalesforce::SalesforceBulkApiPatch
    def create_job(batch_size, send_nulls, no_null_list)
      @batch_size = batch_size
      @send_nulls = send_nulls
      @no_null_list = no_null_list

      xml = "#{@XML_HEADER}<jobInfo xmlns=\"http://www.force.com/2009/06/asyncapi/dataload\">"
      xml += "<operation>#{@operation}</operation>"
      xml += "<object>#{@sobject}</object>"
      # This only happens on upsert
      if !@external_field.nil?
        xml += "<externalIdFieldName>#{@external_field}</externalIdFieldName>"
      end
      xml += "<concurrencyMode>Serial</concurrencyMode>"
      xml += "<contentType>XML</contentType>"
      xml += "</jobInfo>"

      path = "job"
      headers = Hash['Content-Type' => 'application/xml; charset=utf-8']

      response = @connection.post_xml(nil, path, xml, headers)
      response_parsed = XmlSimple.xml_in(response)

      # response may contain an exception, so raise it
      raise SalesforceException.new("#{response_parsed['exceptionMessage'][0]} (#{response_parsed['exceptionCode'][0]})") if response_parsed['exceptionCode']

      @job_id = response_parsed['id'][0]
    end
  end

  SalesforceBulkApi::Job.prepend DiscourseSalesforce::SalesforceBulkApiPatch
end

on(:user_created) do |user|
  if !SiteSetting.must_approve_users? || user.approved?
    ::Jobs.enqueue(
      :sf_update_contact_record,
      user_id: user.id,
    )
  end
end

on(:user_updated) do |user|
  if !SiteSetting.must_approve_users? || user.approved?
    ::Jobs.enqueue(
      :sf_update_contact_record,
      user_id: user.id,
    )
  end
end

on(:user_approved) do |user|
  ::Jobs.enqueue(
    :sf_update_contact_record,
    user_id: user.id,
    queue: "critical"
  )
  # sync memberships on user approved
  user_groups = user.groups.where(automatic: false)
  user_groups.each do |group|
    ::Jobs.enqueue_in(
      2.seconds,
      :sf_update_group_membership,
      user_id: user.id,
      group_id: group.id,
      action: "add",
      queue: "ultra_low"
    )
  end
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

on(:user_added_to_group) do |user, group, opts|
  if !opts[:automatic] && user.approved?
    ::Jobs.enqueue(
      :sf_update_group_membership,
      user_id: user.id,
      group_id: group.id,
      action: "add"
    )
  end
end

on(:user_removed_from_group) do |user, group|
  if !group.automatic && user.approved?
    ::Jobs.enqueue(
      :sf_update_group_membership,
      user_id: user.id,
      group_id: group.id,
      action: "remove"
    )
  end
end

on(:group_created) do |group|
  unless group.automatic
    ::Jobs.enqueue(
      :sf_update_group,
      group_id: group.id,
    )
  end
end

on(:group_updated) do |group|
  unless group.automatic
    ::Jobs.enqueue(
      :sf_update_group,
      group_id: group.id,
    )
  end
end
