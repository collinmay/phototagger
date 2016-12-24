Sequel.migration do
  change do
    alter_table(:imgur_photos) do
      add_column :fullres_mp4_url, String, :size => 255, :fixed => true
      add_column :fullres_gifv_url, String, :size => 255, :fixed => true
      add_column :is_animated, TrueClass
    end
  end
end
