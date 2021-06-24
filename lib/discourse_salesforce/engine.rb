# frozen_string_literal: true

module ::DiscourseSalesforce
  PLUGIN_NAME ||= 'discourse_salesforce'

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseSalesforce
  end
end