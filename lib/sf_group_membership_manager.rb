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
        @client.create!(
          'Member__c',
          Discourse_Membership__c: get_discourse_membership_id,
          Contact__c: get_contact_id
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
        WHERE Name='#{@group.full_name}'"
      ).first&.Id
    end

    def get_membership_id
      @client.query(
        "SELECT Id
        FROM Member__c
        WHERE Contact__r.Name='#{@user.name}'
        AND Discourse_Membership__r.Name='#{@group.full_name}'"
      ).first&.Id
    end

    def get_contact_id
      @client.query(
        "SELECT Id
        FROM Contact
        WHERE #{SiteSetting.discourse_user_id_custom_field}=#{@user.id}
        OR Email='#{@user.email}'"
      ).first&.Id
    end

    def membership_exists?
      !!get_membership_id
    end
  end
end
