Sequel.migration do
  change do
    alter_table(:users) do
      add_column :is_superuser, FalseClass, :default => false
    end
  end
end
