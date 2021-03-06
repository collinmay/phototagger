#require "rakeup"

task default: [:migrate, :webpack, :run]

task :run do
  system("bundle exec rackup")
end

task :migtest, [:version] do |t, args|
  require "sequel"
  Sequel.extension :migration
  
  db = Sequel.connect("mysql2://tagger:S6L52XKuqR56PGqZujM8z2pr@localhost/tagger_mig_test")

  require "logger"
  db.loggers << Logger.new($stdout)
  
  if args[:version] then
    puts "Migrating to version #{args[:version]}"
    Sequel::Migrator.run(db, "migrations", :target => args[:t].to_i)
  else
    if Sequel::Migrator.is_current?(db, "migrations") then
      puts "No migrations necessary"
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "migrations")
    end
  end  
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
    Sequel::Migrator.run(db, "migrations", :target => args[:t].to_i)
  else
    if Sequel::Migrator.is_current?(db, "migrations") then
      puts "No migrations necessary"
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "migrations")
    end
  end
end

task :webpack do
  Dir.chdir "frontend" do
    system("webpack")
  end
end

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = "--format doc"
  end
rescue LoadError
end
