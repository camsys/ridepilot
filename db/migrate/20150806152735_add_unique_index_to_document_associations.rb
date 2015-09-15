class AddUniqueIndexToDocumentAssociations < ActiveRecord::Migration
  def change
    add_index :document_associations, [:document_id, :associable_id, :associable_type], 
      name: "index_document_associations_unique_document_id_associable",
      unique: true
  end
end
