Rake.application.instance_variable_get('@tasks').delete('db:test:prepare')
namespace :db do
  namespace :test do
    task :prepare => :environment do
      if (ENV['RAILS_ENV'] == "test")
        Rake::Task["db:drop"].invoke
        Rake::Task["db:create"].invoke
        Rake::Task["db:schema:load"].invoke
        Rake::Task["ridepilot:load_locales"].invoke
      else
        system("rake db:test:prepare RAILS_ENV=test")
      end
    end
  end
end
