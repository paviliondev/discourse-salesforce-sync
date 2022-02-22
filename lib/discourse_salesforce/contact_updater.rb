# frozen_string_literal: true

module DiscourseSalesforce
  class ContactUpdater
    attr_accessor :user

    def initialize(user: nil)
      @user = user
      @client = RestClient.instance
      @notifier = DiscourseSalesforce::Notifier.new(:contact_updater)
    end

    def create_or_update_record
      @notifier.wrap(username: @user.username) do
        if record_exists?
          update_record
        else
          create_record
        end
      end
    end

    def record_exists?
      !!fetch_contact
    end

    def build_contact(bulk_user: nil)
      @user = bulk_user if bulk_user.present?
      first_name, last_name = get_name

      contact = {
        FirstName: first_name,
        LastName: last_name || @user.username,
        Email: @user.email,
        Discourse_Email__c: @user.email,
        AccountId: get_account_id,
        Discourse_Username__c: @user.username,
        Discourse_Organization__c: get_employer_name
      }

      if user_id_custom_field
        contact[user_id_custom_field.to_sym] = @user.id
      end

      contact
    end

    def create_record
      @client.create!('Contact', build_contact)
    end

    def update_record
      fetch_contact
      first_name, last_name = get_name
      last_name ||= @user.username
      modify('FirstName', first_name)
      modify('LastName', last_name)
      modify('Discourse_Username__c', @user.username)
      modify('Discourse_Email__c', @user.email)
      modify('Discourse_Organization__c', get_employer_name)
      if user_id_custom_field
        modify(user_id_custom_field, @user.id)
      end

      save!
    end

    def reload_user!
      @user.reload
    end

    def fetch_contact
      return @contact unless @contact.nil?

      query = "SELECT
        Id,
        FirstName,
        LastName,
        Name,
        Email,
        Discourse_Username__c,
        Discourse_User_Id__c
        FROM Contact
        WHERE #{user_id_custom_field}=#{@user.id}
        OR Email='#{@user.email}'"

      result = @client.query(query)
      @contact = result.first
    end

    def modify(key, value)
      @contact[key] = value
    end

    def save!
      @contact.delete 'Name'
      @contact.save!
    end

    def nhs_email_domain?
      domain = Mail::Address.new(@user.email).domain
      nhs_domains = SiteSetting.discourse_salesforce_nhs_email_domains.split('|')
      nhs_domains.any? { |nhs_domain| domain.end_with?(nhs_domain) }
    end

    def get_account_id
      @map ||= Hash[@client.query("select Id,Name from Account").pluck(:Name, :Id)]
      @map[get_account_name]
    end

    def get_account_name
      nhs_email_domain? ?
        SiteSetting.discourse_salesforce_nhs_account_name :
        SiteSetting.discourse_salesforce_non_nhs_account_name
    end

    def get_name
      if @user.name.present?
        @user.name.split(' ')
      else
        [
          nil,
          @user.username
        ]
      end
    end

    def get_employer_name
      if cf = SiteSetting.discourse_salesforce_employer_custom_field_name.presence
        field_id = UserField.find_by_name(cf)&.id
        @user.user_fields[field_id.to_s]
      end
    end

    def user_id_custom_field
      SiteSetting.discourse_salesforce_discourse_user_id_custom_field
    end
  end
end
