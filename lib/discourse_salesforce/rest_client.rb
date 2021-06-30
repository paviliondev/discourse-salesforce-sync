# frozen_string_literal: true

module DiscourseSalesforce
  class RestClient
    def self.instance
      notifier = DiscourseSalesforce::Notifier.new(:rest_client)
      notifier.wrap do
        @@instance ||= Restforce.new(
          username: SiteSetting.discourse_salesforce_username,
          password: SiteSetting.discourse_salesforce_password,
          client_id: SiteSetting.discourse_salesforce_client_id,
          client_secret: SiteSetting.discourse_salesforce_client_secret,
          host: SiteSetting.discourse_salesforce_host,
        )
      end
    end

    def self.reset!
      @@instance = nil
      instance
    end

    def self.bulk_api_instance
      @@authenticated ||= false

      if !@@authenticated
        instance.authenticate!
        @@authenticated = true
      end

      @@bulk_api_instance ||= SalesforceBulkApi::Api.new(instance)
    end

    def self.reset_bulk_api_instance!
      @@bulk_api_instance = nil
      @@authenticated = false
      bulk_api_instance
    end
  end
end
