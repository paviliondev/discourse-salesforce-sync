# frozen_string_literal: true

require "rails_helper"

describe DiscourseSalesforce::RestClient do
  before do
    SiteSetting.discourse_salesforce_username = "dummyuser"
    SiteSetting.discourse_salesforce_password = "dummypass"
    SiteSetting.discourse_salesforce_client_id = "client123"
    SiteSetting.discourse_salesforce_client_secret = "secretabc"
  end

  it "creates a single instance of the RestForce client" do
    client_1 = DiscourseSalesforce::RestClient.instance
    client_2 = DiscourseSalesforce::RestClient.instance

    expect(client_1.object_id).to eq(client_2.object_id)
  end

  context "#reset" do
    it "creates a new client object" do
      client_1 = DiscourseSalesforce::RestClient.instance
      client_2 = DiscourseSalesforce::RestClient.reset!

      expect(client_1.object_id).not_to eq(client_2.object_id)
    end
  end
end
