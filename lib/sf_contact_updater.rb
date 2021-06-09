# frozen_string_literal: true

module DiscourseSalesforce
  class ContactUpdater
    def initialize(user)
      @user = user
    end

    def create_or_update_record
      if record_exists?
        update_record
      else
        create_record
      end
    end

    def record_exists?
      !!fetch_contact
    end

    def create_record
      client = RestClient.instance

      first_name, last_name = split_name
      email = @user.email
      account_name = nhs_email_domain?(email) ? 
        SiteSetting.nhs_account_name : 
        SiteSetting.non_nhs_account_name
      account_id = fetch_account_id(account_name)
      contact_hash = {
        FirstName: first_name, 
        LastName: last_name, 
        Email: email,
        AccountId: account_id
      }
      contact_hash[SiteSetting.discourse_user_id_custom_field.to_sym] = @user.id

      client.create(
        'Contact',
        contact_hash
      )
    end

    def update_record
      fetch_contact
      first_name, last_name = split_name
      modify('FirstName', first_name)
      modify('LastName', last_name)
      modify('Email', @user.email)
      save!
    end

    private

    def split_name
      @user.name.split(' ')
    end

    def fetch_contact
      return @contact unless @contact.nil?

      client = RestClient.instance
      query = "SELECT 
        Id, 
        FirstName, 
        LastName, 
        Name, 
        Email 
        FROM Contact 
        WHERE #{SiteSetting.discourse_user_id_custom_field}=#{@user.id}
        OR Email='#{@user.email}'"

      result = client.query(query)
      @contact = result.first
    end

    def modify(key, value)
      @contact[key] = value
    end

    def save!
      @contact.delete 'Name'
      @contact.save!
    end

    def nhs_email_domain?(email)
      SiteSetting.nhs_email_domains.include?(Mail::Address.new(email).domain)
    end

    def fetch_account_id(account_name)
      client = RestClient.instance
      query = "SELECT Id from Account WHERE Name='#{account_name}'"
      result = client.query(query)
      result.first.Id
    end
  end
end
