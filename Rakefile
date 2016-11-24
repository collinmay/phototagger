#require "rakeup"

task default: [:migrate, :run]

task :run do
  system("bundle exec rackup")
end

task :migrate, [:version] do |t, args|
  require "sequel"
  require "yaml"
  Sequel.extension :migration
  config = YAML.load(File.read("config.yml"))
  db_path = config["production"]["db_path"]
  db = Sequel.connect(db_path)
  if args[:version] then
    puts "Migrating to version #{args[:version]}"
    Sequel::Migrator.run(db, "migrations", target => args[:version].to_i)
  else
    puts "Migrating to latest"
    Sequel::Migrator.run(db, "migrations")
  end
end

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = "--format doc"
  end
rescue LoadError
end
