Sequel.migration do
  change do
    create_table(:schema_info) do
      Integer :version, :default=>0, :null=>false
    end
    
    create_table(:users) do
      primary_key :id
      String :google_id, :size=>21, :fixed=>true
    end
    
    create_table(:photos, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :user_id, :users, :key=>[:id]
      String :provider
      
      index [:user_id], :name=>:owner_id
    end
    
    create_table(:tags, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :user_id, :users, :key=>[:id]
      String :title, :size=>128, :fixed=>true
      
      index [:user_id], :name=>:owner_id
    end
    
    create_table(:google_photos, :ignore_index_errors=>true) do
      foreign_key :photo_id, :photos, :null=>false, :key=>[:id]
      String :google_id, :size=>21, :fixed=>true
      String :fullres_url, :size=>128, :fixed=>true
      String :largethumb_url, :size=>128, :fixed=>true
      
      primary_key [:photo_id]
      
      index [:google_id]
    end
    
    create_table(:imgur_photos, :ignore_index_errors=>true) do
      foreign_key :photo_id, :photos, :null=>false, :key=>[:id]
      String :imgur_id, :size=>8, :fixed=>true
      String :fullres_url, :size=>255, :fixed=>true
      
      primary_key [:photo_id]
      
      index [:imgur_id]
    end
    
    create_table(:photos_tags, :ignore_index_errors=>true) do
      foreign_key :photo_id, :photos, :null=>false, :key=>[:id]
      foreign_key :tag_id, :tags, :null=>false, :key=>[:id]
      
      primary_key [:photo_id, :tag_id]
      
      index [:tag_id, :photo_id]
    end
    
    create_table(:tags_users, :ignore_index_errors=>true) do
      foreign_key :owner_id, :users, :null=>false, :key=>[:id]
      foreign_key :tag_id, :tags, :null=>false, :key=>[:id]
      
      primary_key [:owner_id, :tag_id]
      
      index [:tag_id, :owner_id]
    end
  end
end
