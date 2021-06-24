# frozen_string_literal: true

module Jobs
  class SfUpdateGroup < ::Jobs::Base
    def execute(args)
      group = Group.find(args[:group_id])
      updater = DiscourseSalesforce::GroupUpdater.new(group: group)
      updater.create_or_update_record
    end
  end
end
