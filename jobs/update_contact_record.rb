# frozen_string_literal: true

module Jobs
  class SfUpdateContactRecord < ::Jobs::Base
    def execute(args)
      user = User.find(args[:user_id])
      updater = DiscourseSalesforce::ContactUpdater.new(user: user)
      updater.create_or_update_record
    end
  end
end
