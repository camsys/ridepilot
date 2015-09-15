namespace :utility do

  desc 'List all missing translation keys'
  task :find_missing_translation_keys => :environment do
    seed_file = File.join(Rails.root, 'db', 'tasks', 'find_missing_translation_keys.rb')
    load(seed_file) if File.exist?(seed_file)
  end

  desc 'show customer reflections'
  task :show_customer_reflections => :environment do
    reflections = Customer.reflect_on_all_associations
    reflections.each do |reflection|
      puts ":#{reflection.macro} => :#{reflection.name}"
    end
  end

end