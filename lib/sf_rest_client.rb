# frozen_string_literal: true

module DiscourseSalesforce
  class RestClient
    def self.instance
      @@instance ||= Restforce.new(
        username: SiteSetting.discourse_salesforce_username,
        password: SiteSetting.discourse_salesforce_password,
        client_id: SiteSetting.discourse_salesforce_client_id,
        client_secret: SiteSetting.discourse_salesforce_client_secret,
        host: SiteSetting.discourse_salesforce_host,
      )
    end

    def self.reset!
      @@instance = nil
      instance
    end
  end
end
