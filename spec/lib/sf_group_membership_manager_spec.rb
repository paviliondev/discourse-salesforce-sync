# frozen_string_literal: true

require "rails_helper"

describe DiscourseSalesforce::GroupMembershipManager do
  let(:sf_user_email) { "faizan@gagan.com" }
  let(:sf_user) { Fabricate(:user, email: sf_user_email) }
  let(:sf_group) { Fabricate(:group) }

  class RestforceMock
  end

  before do
    DiscourseSalesforce::RestClient.stubs(:instance).returns(RestforceMock.new)
    RestforceMock.any_instance.stubs(:create!).returns("created")
    RestforceMock.any_instance.stubs(:destroy!).returns("destroyed")
    sf_group_membership_manager.stubs(:get_discourse_membership_id).returns(1)
    sf_group_membership_manager.stubs(:get_contact_id).returns(1)
  end

  let(:sf_group_membership_manager) {
    DiscourseSalesforce::GroupMembershipManager.new(sf_user, sf_group)
  }

  context "#add_user_to_group" do
    it "adds user to the group if not already added" do
      sf_group_membership_manager.stubs(:membership_exists?).returns(false)
      expect(sf_group_membership_manager.add_user_to_group).to eq("created")
    end

    it "does nothing if user is already a member of the group" do
      sf_group_membership_manager.stubs(:membership_exists?).returns(true)
      expect(sf_group_membership_manager.add_user_to_group).to eq(nil)
    end
  end

  context "#remove_user_from_group" do
    it "removes user from group if user is a member of the group" do
      sf_group_membership_manager.stubs(:get_membership_id).returns(1)
      expect(sf_group_membership_manager.remove_user_from_group).to eq("destroyed")
    end

    it "does nothing if user is isn't a member of the group" do
      sf_group_membership_manager.stubs(:get_membership_id).returns(nil)
      expect(sf_group_membership_manager.remove_user_from_group).to eq(nil)
    end
  end
end
