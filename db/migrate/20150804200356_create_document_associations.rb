class CreateDocumentAssociations < ActiveRecord::Migration
  def change
    create_table :document_associations do |t|
      t.references :document, index: true 

      # Disable automatic index creation, otherwise we get an error:
      #   Index name 
      #   'index_document_associations_on_associable_id_and_associable_type' on 
      #   table 'document_associations' is too long; the limit is 63 characters
      t.references :associable, polymorphic: true, index: false

      t.timestamps
    end
    
    add_index :document_associations, [:associable_id, :associable_type], name: "index_document_associations_on_associable_id_and_associable_typ"
  end
end
