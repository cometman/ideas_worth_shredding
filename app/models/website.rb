class Website < ActiveRecord::Base

  def self.seed_websites
    raw_json = RestClient.get "https://raw.githubusercontent.com/BigMcLargeHuge/opensources/master/notCredible/notCredible.json"
    websites = JSON.parse(raw_json) 
    websites.each do |site|
      next if Website.where(domain: site[0]).present?
      website = Website.create(domain: site[0], tag: site[1]["type"])
      website.save
    end
  end
end
