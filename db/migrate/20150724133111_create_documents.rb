class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.references :documentable, polymorphic: true, index: true
      t.string     :description
      t.string     :document_file_name
      t.string     :document_content_type
      t.integer    :document_file_size
      t.datetime   :document_updated_at

      t.timestamps
    end
  end
end
