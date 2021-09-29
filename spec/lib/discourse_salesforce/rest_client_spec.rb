# frozen_string_literal: true

require_relative '../../plugin_helper'

describe DiscourseSalesforce::RestClient do
  class RestforceMock
    def authenticate!
      true
    end
  end

  class BulkApiMock
  end

  let(:rest_client) { @client || RestforceMock.new }
  let(:bulk_client) { @bulk_client || RestforceMock.new }

  before do
    Restforce.stubs(:new).returns(RestforceMock.new)
    SalesforceBulkApi::Api.stubs(:new).returns(BulkApiMock.new)
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

  it "creates a single instance of bulk api client" do
    client_1 = DiscourseSalesforce::RestClient.bulk_api_instance
    client_2 = DiscourseSalesforce::RestClient.bulk_api_instance

    expect(client_1.object_id).to eq(client_2.object_id)
  end

  context "#reset_bulk_api_instance!" do
    it "creates a new bulk api client object" do
      client_1 = DiscourseSalesforce::RestClient.instance
      client_2 = DiscourseSalesforce::RestClient.reset_bulk_api_instance!

      expect(client_1.object_id).not_to eq(client_2.object_id)
    end
  end
end
