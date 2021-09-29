# frozen_string_literal: true

require_relative '../../plugin_helper'

describe DiscourseSalesforce::ContactUpdater do
  let(:sf_user_email) { "faizan@gagan.com" }
  let(:sf_user) { Fabricate(:user, email: sf_user_email) }
  let(:sf_contact_updater) { DiscourseSalesforce::ContactUpdater.new(user: sf_user) }

  class RestforceMock
  end

  before do
    DiscourseSalesforce::RestClient.stubs(:instance).returns(RestforceMock.new)
  end

  context "#create_or_update_record" do
    it "creates a new Contact Record using the discourse user" do
      sf_contact_updater.stubs(:record_exists?).returns(false)
      sf_contact_updater.stubs(:create_record).returns(true)

      sf_contact_updater.expects(:create_record).once
      sf_contact_updater.expects(:update_record).never
      sf_contact_updater.create_or_update_record
    end

    it "updates an existing Contact Record using the discourse user" do
      sf_contact_updater.stubs(:record_exists?).returns(true)
      sf_contact_updater.stubs(:update_record).returns(true)

      sf_contact_updater.expects(:update_record).once
      sf_contact_updater.expects(:create_record).never
      sf_contact_updater.create_or_update_record
    end
  end

  context "#nhs_email_domain?" do
    before do
      SiteSetting.discourse_salesforce_nhs_email_domains = "nhs.net|nhs.com"
    end

    it "detects non-nhs domains correctly" do
      expect(sf_contact_updater.nhs_email_domain?).to eq(false)
    end

    it "detects nhs domains correctly" do
      sf_user.email = "hello@nhs.net"
      sf_user.save!
      sf_contact_updater.reload_user!
      expect(sf_contact_updater.nhs_email_domain?).to eq(true)
    end

    it "detects nhs sub-domains correctly" do
      sf_user.email = "hello@world.nhs.net"
      sf_user.save!
      sf_contact_updater.reload_user!
      expect(sf_contact_updater.nhs_email_domain?).to eq(true)
    end

    it "detects non-nhs sub-domains correctly" do
      sf_user.email = "hello@world.nhsx.net"
      sf_user.save!
      sf_contact_updater.reload_user!
      expect(sf_contact_updater.nhs_email_domain?).to eq(false)
    end
  end
end
