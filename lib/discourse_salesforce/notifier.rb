# frozen_string_literal: true

module DiscourseSalesforce
  class Notifier
    attr_reader :context
    attr_accessor :error,
                  :error_attrs

    def initialize(context, group_array = nil)
      @context = context
      @group_array = group_array.presence
    end

    def wrap(attrs = {}, &block)
      begin
        block.call
      rescue Restforce::ResponseError, Restforce::AuthenticationError => error
        @error_attrs = attrs
        @error = error
        self.send
      end
    end

    def send
      post_opts = {
        title: I18n.t("discourse_salesforce.notifier.error.title"),
        target_group_names: 'admins',
        archetype: Archetype.private_message
      }

      post_opts[:raw] = @context == :data_integrity ?
        data_integrity_post_body : post_body

      creator = PostCreator.new(Discourse.system_user, post_opts)
      creator.create
    end

    def post_body
      <<~EOF
        context: #{I18n.t("discourse_salesforce.notifier.error.context.#{@context.to_s}")}
        error: #{@error.message}
        details: #{@error_attrs.map { |k, v| "#{k}: #{v}" }.join("\n")}
      EOF
    end

    def data_integrity_post_body
      <<~EOF
        context: #{I18n.t("discourse_salesforce.notifier.error.context.#{@context.to_s}")}
        details: The data integrity check failed for these groups: \n - #{@group_array.join("\n - ")}
      EOF
    end
  end
end
