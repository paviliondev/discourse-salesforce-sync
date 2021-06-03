# frozen_string_literal: true

require "rails_helper"

describe DiscourseSalesforce::ContactUpdater do
  let(:sf_user_email) { "faizan@gagan.com" }
  let(:sf_user) { Fabricate(:user, email: sf_user_email) }
  let(:sf_contact_updater) { DiscourseSalesforce::ContactUpdater.new(sf_user) }

  def stub_oauth_request
    stub_request(:post, "https://login.salesforce.com/services/oauth2/token")
      .with(
        body: {
          "client_id" => SiteSetting.discourse_salesforce_client_id,
          "client_secret" => SiteSetting.discourse_salesforce_client_secret,
          "grant_type" => "password",
          "password" => SiteSetting.discourse_salesforce_password,
          "username" => SiteSetting.discourse_salesforce_username
        },
        headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Content-Type' => 'application/x-www-form-urlencoded',
        'User-Agent' => 'Faraday v1.4.2'
        })
      .to_return(status: 200, body: '{
        "access_token": "00D3G0000008kTM!AQgAQPglEdG0AX_WRahnit8UBp7B5poJSmEUuNCn6Jjh7nL_e11DYkaCX07sOpcYAAyHeV9hcxEyX5AQX5sNlrxBdaaP4b9l",
        "instance_url": "https://digitalhealth--discourse.my.salesforce.com",
        "id": "https://test.salesforce.com/id/00D3G0000008kTMUAY/0053G000000gGbwQAE",
        "token_type": "Bearer",
        "issued_at": "1622655691544",
        "signature": "mdfAjyLzCdrhzkTNJmlpnpm6J/PZ/ruJ1ZYdN/eFt7E="
      }', headers: {})
  end

  before do
    SiteSetting.discourse_salesforce_username = "dummyuser"
    SiteSetting.discourse_salesforce_password = "dummypass"
    SiteSetting.discourse_salesforce_client_id = "client123"
    SiteSetting.discourse_salesforce_client_secret = "secretabc"
    stub_oauth_request
  end

  def stub_contact_not_exists
    stub_request(:get, "https://digitalhealth--discourse.my.salesforce.com/services/data/v26.0/query?q=SELECT%20Id,%20FirstName,%20LastName,%20Name,%20Email%20from%20Contact%20where%20Email='#{sf_user_email}'")
      .with(
        headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization' => 'OAuth 00D3G0000008kTM!AQgAQPglEdG0AX_WRahnit8UBp7B5poJSmEUuNCn6Jjh7nL_e11DYkaCX07sOpcYAAyHeV9hcxEyX5AQX5sNlrxBdaaP4b9l',
        'User-Agent' => 'Faraday v1.4.2'
      })
      .to_return(status: 200, body: '{
        "totalSize": 0,
        "done": true,
        "records": []
        }', headers: {
        "Content-Type" => "application/json;charset=UTF-8"
      })
  end

  def stub_contact_create_request
    stub_request(:post, "https://digitalhealth--discourse.my.salesforce.com/services/data/v26.0/sobjects/Contact")
      .with(
         body: "{\"FirstName\":\"Bruce\",\"LastName\":\"Wayne\",\"Email\":\"faizan@gagan.com\"}",
         headers: {
         'Accept' => '*/*',
         'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
         'Authorization' => 'OAuth 00D3G0000008kTM!AQgAQPglEdG0AX_WRahnit8UBp7B5poJSmEUuNCn6Jjh7nL_e11DYkaCX07sOpcYAAyHeV9hcxEyX5AQX5sNlrxBdaaP4b9l',
         'Content-Type' => 'application/json',
         'User-Agent' => 'Faraday v1.4.2'
      })
      .to_return(status: 200, body: '{
        "id": "0033G000006gKjPQAU",
        "success": true,
        "errors": []
        }', headers: {})
  end

  def stub_contact_found_request
    stub_request(:get, "https://digitalhealth--discourse.my.salesforce.com/services/data/v26.0/query?q=SELECT%20Id,%20FirstName,%20LastName,%20Name,%20Email%20from%20Contact%20where%20Email='#{sf_user_email}'")
      .with(
         headers: {
         'Accept' => '*/*',
         'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
         'Authorization' => 'OAuth 00D3G0000008kTM!AQgAQPglEdG0AX_WRahnit8UBp7B5poJSmEUuNCn6Jjh7nL_e11DYkaCX07sOpcYAAyHeV9hcxEyX5AQX5sNlrxBdaaP4b9l',
         'User-Agent' => 'Faraday v1.4.2'
      })
      .to_return(status: 200, body: '{
        "totalSize": 1,
        "done": true,
        "records": [
            {
                "attributes": {
                    "type": "Contact",
                    "url": "/services/data/v26.0/sobjects/Contact/0033G000006fPVpQAM"
                },
                "Id": "0033G000006fPVpQAM",
                "FirstName": "Bruce",
                "LastName": "Wayne",
                "Name": "Bruce Wayne",
                "Email": "faizan@gagan.com"
            }
        ]
    }', headers: {
      "Content-Type" => "application/json;charset=UTF-8"
    })
  end

  def stub_contact_update_request
    stub_request(:patch, "https://digitalhealth--discourse.my.salesforce.com/services/data/v26.0/sobjects/Contact/0033G000006fPVpQAM")
      .with(
        body: "{\"FirstName\":\"Bruce\",\"LastName\":\"Wayne\",\"Email\":\"faizan@gagan.com\"}",
        headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization' => 'OAuth 00D3G0000008kTM!AQgAQPglEdG0AX_WRahnit8UBp7B5poJSmEUuNCn6Jjh7nL_e11DYkaCX07sOpcYAAyHeV9hcxEyX5AQX5sNlrxBdaaP4b9l',
        'Content-Type' => 'application/json',
        'User-Agent' => 'Faraday v1.4.2'
        })
      .to_return(status: 200, body: "", headers: {})

    stub_request(:patch, "https://digitalhealth--discourse.my.salesforce.com/services/data/v26.0/sobjects/Contact/0033G000006fPVpQAM")
      .with(
        body: "{\"FirstName\":\"Bruce\",\"LastName\":\"Wayne\",\"Email\":\"hello@world.com\"}",
        headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization' => 'OAuth 00D3G0000008kTM!AQgAQPglEdG0AX_WRahnit8UBp7B5poJSmEUuNCn6Jjh7nL_e11DYkaCX07sOpcYAAyHeV9hcxEyX5AQX5sNlrxBdaaP4b9l',
        'Content-Type' => 'application/json',
        'User-Agent' => 'Faraday v1.4.2'
      })
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_contact_updated_request
    stub_request(:get, "https://digitalhealth--discourse.my.salesforce.com/services/data/v26.0/query?q=SELECT%20Id,%20FirstName,%20LastName,%20Name,%20Email%20from%20Contact%20where%20Email='hello@world.com'")
      .with(
        headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization' => 'OAuth 00D3G0000008kTM!AQgAQPglEdG0AX_WRahnit8UBp7B5poJSmEUuNCn6Jjh7nL_e11DYkaCX07sOpcYAAyHeV9hcxEyX5AQX5sNlrxBdaaP4b9l',
        'User-Agent' => 'Faraday v1.4.2'
        })
      .to_return(status: 200, body:  '{
          "totalSize": 1,
          "done": true,
          "records": [
              {
                  "attributes": {
                      "type": "Contact",
                      "url": "/services/data/v26.0/sobjects/Contact/0033G000006fPVpQAM"
                  },
                  "Id": "0033G000006fPVpQAM",
                  "FirstName": "Bruce",
                  "LastName": "Wayne",
                  "Name": "Bruce Wayne",
                  "Email": "hello@world.com"
              }
          ]
            }', headers: {
            "Content-Type" => "application/json;charset=UTF-8"
      })
  end

  context "#create_record" do
    it "creates a new Contact Record using the discourse user" do
      stub_contact_not_exists
      stub_contact_create_request
      contact_id = sf_contact_updater.create_record
      expect(contact_id).not_to be_nil
    end
  end

  context "#update_record" do
    it "updates an existing Contact Record using the discourse user" do
      stub_contact_found_request
      stub_contact_update_request
      sf_user.email = "hello@world.com"
      sf_user.save!
      sf_contact_updater.reload_user!
      stub_contact_updated_request
      updated = sf_contact_updater.update_record
      expect(updated).to be_truthy
    end
  end
end
