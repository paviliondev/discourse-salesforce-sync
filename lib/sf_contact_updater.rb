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
      client.create('Contact', FirstName: first_name, LastName: last_name, Email: email)
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
      query =  "SELECT Id, FirstName, LastName, Name, Email from Contact where Email='#{@user.email}'"
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
  end
end
