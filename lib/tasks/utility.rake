namespace :utility do

  desc 'List all missing translation keys'
  task :find_missing_translation_keys => :environment do
    seed_file = File.join(Rails.root, 'db', 'tasks', 'find_missing_translation_keys.rb')
    load(seed_file) if File.exist?(seed_file)
  end

end