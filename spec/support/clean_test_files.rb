RSpec.configure do |config|
  config.after(:suite) do
    # Paperclip is configured to store attachments here in test mode
    test_files = Rails.root.join("tmp", "test_files")
    FileUtils.remove_dir(test_files) if test_files.exist?
  end
end
