# frozen_string_literal: true

module Jobs
  class SfCreateContactAndUpdateMemberships < ::Jobs::Base
    def execute(args)
      user = User.find(args[:user_id])
      updater = DiscourseSalesforce::ContactUpdater.new(user: user)
      updater.create_or_update_record
      group_ids = user.groups.where(automatic: false).pluck(:id)
      return if group_ids.blank?

      client = DiscourseSalesforce::RestClient.instance
      contact_id = client.query("Select Id from Contact Where Discourse_User_Id__c=#{user.id}").first&.Id
      return if !contact_id

      group_fetch_query = "SELECT Discourse_Group_Id__c, Id, Name from Discourse_Membership__c WHERE Discourse_Group_Id__c IN (#{group_ids.join(',')})"
      salesforce_group_ids = client.query(group_fetch_query).map(&:Id)
      return if salesforce_group_ids.blank?

      membership_records = salesforce_group_ids.map do |sf_group_id|
        {
          Discourse_Membership__c: sf_group_id,
          Contact__c: contact_id
        }
      end

      bulk_instance = DiscourseSalesforce::RestClient.bulk_api_instance
      bulk_instance.create!(
        "Member__c",
        membership_records
      )
    end
  end
end
