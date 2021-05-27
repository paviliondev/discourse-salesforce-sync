module DiscourseSalesforce
  class RestClient
    def self.instance
      @@instance ||= Restforce.new
    end
  end
end
