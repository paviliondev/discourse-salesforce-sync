# frozen_string_literal: true

if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start do
    root "plugins/discourse-salesforce-sync"
    track_files "plugins/discourse-salesforce-sync/**/*.rb"
    add_filter { |src| src.filename =~ /(\/spec\/|\/db\/|plugin\.rb|gems)/ }
  end
end

require 'rails_helper'
