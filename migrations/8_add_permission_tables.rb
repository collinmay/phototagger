Sequel.migration do
  change do
    create_table(:permission_groups) do
      primary_key :id
      column :name, String, :unique => true
      
      foreign_key :parent_id, :permission_groups, :on_delete => :cascade, :on_update => :cascade, :null => true
    end
    
    create_table(:permissions) do
      primary_key :id
      column :permission_node, String, :null => false
      foreign_key :group, :permission_groups, :on_delete => :cascade, :on_update => :cascade, :null => false
      column :permitted, FalseClass, :null => false

      index [:permission_node, :group], :unique => true, :name => "node_group_index"
    end
    
    self[:permission_groups].insert(:name => "default", :parent_id => nil)
    default_group_id = self[:permission_groups][:name => "default"][:id]
    
    alter_table(:users) do
      add_foreign_key :permission_group, :permission_groups, :on_delete => :restrict, :on_update => :cascade, :default => default_group_id
    end
  end
end
