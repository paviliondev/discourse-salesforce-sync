# frozen_string_literal: true

describe DiscourseSalesforce::GroupUpdater do
  let(:sf_group) { Fabricate(:group) }
  let(:sf_group_updater) { DiscourseSalesforce::GroupUpdater.new(group: sf_group) }

  class RestforceMock
  end

  before do
    DiscourseSalesforce::RestClient.stubs(:instance).returns(RestforceMock.new)
  end

  context "#create_or_update_record" do
    it "creates a new Contact Record using the discourse user" do
      sf_group_updater.stubs(:group_record_exists?).returns(false)
      sf_group_updater.stubs(:create_record).returns(true)

      sf_group_updater.expects(:create_record).once
      sf_group_updater.expects(:update_record).never
      sf_group_updater.create_or_update_record
    end

    it "updates an existing Contact Record using the discourse user" do
      sf_group_updater.stubs(:group_record_exists?).returns(true)
      sf_group_updater.stubs(:update_record).returns(true)

      sf_group_updater.expects(:update_record).once
      sf_group_updater.expects(:create_record).never
      sf_group_updater.create_or_update_record
    end
  end
end
