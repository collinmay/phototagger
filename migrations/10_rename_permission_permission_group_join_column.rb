Sequel.migration do
  up do
    alter_table(:permission_groups) do
      drop_foreign_key :parent_id
    end
    alter_table(:permissions) do
      rename_column :group, :permission_group_id
    end
  end
  down do
    alter_table(:permission_groups) do
      add_foreign_key :parent_id, :permission_groups, :on_delete => :cascade, :on_update => :cascade, :null => true
    end
    alter_table(:permissions) do
      rename_column :permission_group_id, :group
    end
  end
end
