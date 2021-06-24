# frozen_string_literal: true

module Jobs
  class SfUpdateGroupMembership < ::Jobs::Base
    def execute(args)
      user = User.find(args[:user_id])
      group = Group.find(args[:group_id])
      manager = DiscourseSalesforce::GroupMembershipManager.new(user: user, group: group)

      if args[:action] == "add"
        manager.add_user_to_group
      else
        manager.remove_user_from_group
      end
    end
  end
end
