require "faraday"
require "faraday_middleware"
require_relative "../config.rb"

Sequel.migration do
  up do
    imgur = Faraday.new(:url => "https://api.imgur.com") do |faraday|
      faraday.authorization("Client-ID", IMGUR_API_CLIENT)
      faraday.response :json, :content_type => /\bjson$/
      faraday.adapter Faraday.default_adapter
    end
    
    alter_table(:imgur_photos) do
      add_column :fullres_url, String, :fixed => true, :length => 128
    end

    DB[:imgur_photos].all do |row|
      if row[:imgur_id].is_a? String then
        json = imgur.get("/3/image/#{row[:imgur_id]}").body
        if !json["success"] then
          puts "could not get url for #{row[:imgur_id]}: " + json.to_s
          next
        end
        
        DB[:imgur_photos].where("photo_id = ?", row[:photo_id]).update(:fullres_url => json["data"]["link"])
      end
    end
  end

  down do
    alter_table(:imgur_photos) do
      drop_column :fullres_url
    end
  end
end
