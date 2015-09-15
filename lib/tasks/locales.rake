require 'rake'

namespace :ridepilot do

  class Hash
	  def each_with_parents(parents=[], &blk)
	    each do |k, v|
	      Hash === v ? v.each_with_parents(parents + [k], &blk) : blk.call([parents + [k], v])
	    end
	  end
  end

  desc "Reload database translations from scratch"
  task reload_locales: :environment do
    Rake::Task["ridepilot:clear_locales"].invoke
    Rake::Task["ridepilot:load_locales"].invoke
  end
  
  desc "Clear up existing database translations"
  task clear_locales: :environment do
    TranslationKey.delete_all
    Locale.delete_all
    Translation.delete_all

    puts "Translations have been all cleared."
  end

  desc "Load database translations from config/locales/*.yml files"
  task load_locales: :environment do
  	locales_directory = Rails.root.to_s + "/config/locales/"

    Dir.foreach(locales_directory) do |filename|
    	
      unless filename == "." || filename == ".."

	      puts "Loading locale file #{filename}"

	      y = YAML.load_file(locales_directory + filename)

	      failed = success = skipped = 0
	      
	      y.each_with_parents do |parents, v|

	        locale = parents.shift
	        locale = Locale.find_or_create_by(name: locale)

	        translation_value = v.is_a?(Array) ? v.join(',') : v

          translation_key_name = parents.join('.')
          translation_key = TranslationKey.find_or_create_by!(name: translation_key_name)

          #Check if translation exists.  DO NOT overwrite existing translations.
          existing_translation = Translation.where("translation_key_id = ? AND locale_id = ?", translation_key.id, locale.id)

          if existing_translation.empty?
          	new_translation = Translation.new(translation_key: translation_key, locale: locale, value: translation_value)
          	new_translation.save ? success += 1 : failed += 1
          else
          	skipped += 1
          end

	      end

	      puts "Read #{success+failed} keys, #{success} successful, #{failed} failed, #{skipped} skipped"

  		end

    end
  end

end	