Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      column :google_id, String, :fixed => true, :size => 21
    end

    create_table(:photos) do
      primary_key :id
      foreign_key :owner_id, :users
      column :provider, String
    end

    create_table(:tags) do
      primary_key :id
      foreign_key :owner_id, :users
      column :title, String, :fixed => true, :size => 128
    end
    
    create_join_table(:photo_id => :photos,
                      :tag_id => :tags)

    create_join_table(:owner_id => :users,
                      :tag_id => :tags)

    create_table(:google_photos) do
      column :photo_id, Integer, :primary_key => true
      column :google_id, String, :fixed => true, :size => 21
      column :fullres_url, String, :fixed => true, :size => 128
      column :largethumb_url, String, :fixed => true, :size => 128

      foreign_key [:photo_id], :photos
      index :google_id
    end

    create_table(:imgur_photos) do
      column :photo_id, Integer, :primary_key => true
      column :imgur_id, String, :fixed => true, :size => 8

      foreign_key [:photo_id], :photos
      index :imgur_id
    end
  end
end
