Sequel.migration do
  change do
    alter_table(:users) do
      rename_column :permission_group, :permission_group_id
    end
  end
end
