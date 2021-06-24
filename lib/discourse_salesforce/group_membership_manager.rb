# frozen_string_literal: true

module DiscourseSalesforce
  class GroupMembershipManager
    def initialize(user, group)
      @user = user
      @group = group
      @client = RestClient.instance
    end

    def add_user_to_group
      unless membership_exists?
        discourse_membership_id = get_discourse_membership_id
        contact_id = get_contact_id

        @client.create!(
          'Member__c',
          Discourse_Membership__c: discourse_membership_id,
          Contact__c: contact_id
        )
      end
    end

    def remove_user_from_group
      membership_id = get_membership_id
      if membership_id.present?
        @client.destroy!(
          'Member__c',
          membership_id
        )
      end
    end

    def get_discourse_membership_id
      @client.query(
        "SELECT Id
        FROM Discourse_Membership__c
        WHERE Name='#{@group.name}'"
      ).first&.Id
    end

    def get_membership_id
      @client.query(
        "SELECT Id
        FROM Member__c
        WHERE Contact__r.#{SiteSetting.discourse_salesforce_discourse_user_id_custom_field}=#{@user.id}
        AND Discourse_Membership__r.Name='#{@group.name}'"
      ).first&.Id
    end

    def get_contact_id
      @client.query(
        "SELECT Id
        FROM Contact
        WHERE #{SiteSetting.discourse_salesforce_discourse_user_id_custom_field}=#{@user.id}
        OR Email='#{@user.email}'"
      ).first&.Id
    end

    def membership_exists?
      !!get_membership_id
    end
  end
end
