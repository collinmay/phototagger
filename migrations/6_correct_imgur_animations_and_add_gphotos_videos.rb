Sequel.migration do
  change do
    alter_table(:imgur_photos) do
      drop_column :fullres_mp4_url
      drop_column :fullres_gifv_url
      drop_column :is_animated
      add_column :fullres_imgthumb_url, String, :size => 255, :fixed => true
    end

    alter_table(:photos) do
      add_column :is_video, TrueClass
    end
  end
end
