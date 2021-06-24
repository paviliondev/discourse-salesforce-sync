# frozen_string_literal: true

module DiscourseSalesforce
  class GroupUpdater
    attr_accessor :group

    def initialize(group: nil)
      @group = group
      @client = RestClient.instance
    end

    def create_or_update_record
      if group_record_exists?
        update_record
      else
        create_record
      end
    end

    def group_record_exists?
      !!fetch_record
    end

    def fetch_record
      return @group_record if @group_record.present?

      query = "SELECT Id,
        Name,
        Discourse_Membership_Long_Name__c
        FROM Discourse_Membership__c
        WHERE Discourse_Group_Id__c=#{@group.id}"

      result = @client.query(query)
      @group_record = result.first
    end

    def build_group_record(bulk_group: nil)
      @group = bulk_group if bulk_group.present?

      group_record = {
        Name: @group.name,
        Discourse_Membership_Long_Name__c: @group.full_name,
        Discourse_Group_Id__c: @group.id
      }

      group_record
    end

    def create_record
      @client.create('Discourse_Membership__c', build_group_record)
    end

    def update_record
      record = build_group_record
      record[:Id] = fetch_record[:Id]
      @client.update!('Discourse_Membership__c', record)
    end
  end
end
