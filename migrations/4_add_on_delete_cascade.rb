Sequel.migration do
  up do
    alter_table(:google_photos) do
      drop_foreign_key [:photo_id]
      add_foreign_key [:photo_id], :photos, :null => false, :on_delete => :cascade
    end
    alter_table(:imgur_photos) do
      drop_foreign_key [:photo_id]
      add_foreign_key [:photo_id], :photos, :null => false, :on_delete => :cascade
    end
  end

  down do
    alter_table(:google_photos) do
      drop_foreign_key [:photo_id]
      add_foreign_key [:photo_id], :photos, :null => false, :key => [:id]
    end
    alter_table(:imgur_photos) do
      drop_foreign_key [:photo_id]
      add_foreign_key [:photo_id], :photos, :null => false, :key => [:id]
    end
  end
end
