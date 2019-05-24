Sequel.migration do
  change do
    alter_table(:photos) do
      add_column :import_date, DateTime, :default => DateTime.now
    end
  end
end
