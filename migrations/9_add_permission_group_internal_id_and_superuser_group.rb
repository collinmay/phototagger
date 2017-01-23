Sequel.migration do
  up do
    alter_table(:permission_groups) do
      add_column :internal_id, String, :unique => true, :null => true
    end
    self[:permission_groups].where(:name => "default").update(:internal_id => "default")
    self[:permission_groups].insert(:name => "superusers", :internal_id => "superusers")
  end

  down do
    alter_table(:permission_groups) do
      drop_column :internal_id
    end
  end
end
