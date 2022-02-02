# frozen_string_literal: true

module Jobs
  class SfDataIntegrityCheck < ::Jobs::Scheduled
    every 1.day

    def execute(args)
      rest_client = DiscourseSalesforce::RestClient.instance
      discourse_group_user_count = {}
      Group.where(automatic: false).each do |group|
        users = group.users.real
        users = users.where(approved: true) if SiteSetting.must_approve_users?
        discourse_group_user_count[group.name] = users.count
      end
      aggregate = rest_client.query(
        <<-SOQL_QUERY
        SELECT Discourse_Membership__r.Name, COUNT(Id)
        FROM Member__c
        GROUP BY Discourse_Membership__r.Name
        SOQL_QUERY
      )

      salesforce_group_user_count = aggregate.to_a.pluck(:Name, :expr0).to_h

      unequal_count_groups = []
      discourse_group_user_count.each do |group_name, count|
        unequal_count_groups << group_name if (salesforce_group_user_count[group_name] || 0) != count
      end

      notifier = DiscourseSalesforce::Notifier.new(:data_integrity, unequal_count_groups)
      notifier.send if SiteSetting.discourse_salesforce_enable_sync_error_notifs
    end
  end
end
