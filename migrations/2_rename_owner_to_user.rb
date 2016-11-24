Sequel.migration do
  change do
    alter_table :photos do
      rename_column :owner_id, :user_id
    end

    alter_table :tags do
      rename_column :owner_id, :user_id
    end
  end
end
