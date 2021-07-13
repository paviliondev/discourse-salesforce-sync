# frozen_string_literal: true

require "rails_helper"

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
end
