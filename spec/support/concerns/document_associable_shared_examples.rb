require 'spec_helper'

# For model specs
RSpec.shared_examples "an associable for a document" do
  describe "instance" do
    before do
      # Set @owner in the described class
      fail "@owner instance variable required" unless defined? @owner
      
      described_class_factory = described_class.name.underscore.to_sym
      owner_factory = @owner.class.name.underscore.to_sym
      @example = create described_class_factory, owner_factory => @owner
    end
    
    it "has many document associations" do
      expect(described_class.reflect_on_association(:document_associations).macro).to  eq :has_many
    end
    
    it "destroys associated document associations when it is destroyed" do
      3.times { create :document_association, document: create(:document, documentable: @owner), associable: @example }
      expect {
        @example.reload.destroy
      }.to change(DocumentAssociation, :count).by(-3)
    end

    it "accepts nested document associations" do
      @example.document_associations_attributes = 3.times.collect { {document_id: create(:document, documentable: @owner).id} }
      expect {
        @example.save
      }.to change(DocumentAssociation, :count).by(3)
    end
    
    it "destroys associated document associations when the destroy attribute is present" do
      3.times { create :document_association, document: create(:document, documentable: @owner), associable: @example }
      expect(@example.document_associations.count).to eql 3
      
      @example.document_associations_attributes = @example.document_associations(true).collect { |association| association.attributes.merge({:_destroy => "1"}) }
      expect {
        @example.save
      }.to change(DocumentAssociation, :count).by(-3)
    end
    
    it "rejects new document associations with a blank document id" do
      @example.document_associations_attributes = [ { document_id: nil } ]
      expect {
        @example.save
      }.not_to change(DocumentAssociation, :count)
    end
    
    # Normally, validates_uniqueness_of with :scope only works on already 
    # persisted records. With accepts_nested_attributes_for, we could be adding
    # many new records at once, so we want to ensure that they are unique even
    # before they are saved
    it "does not allow duplicate nested document associations" do
      document = create :document, documentable: @owner
      @example.document_associations_attributes = 2.times.collect { {document_id: document.id} }
      expect {
        @example.save
      }.not_to change(DocumentAssociation, :count)
    end
  end
end

# For controller specs
RSpec.shared_examples "a controller that accepts nested attributes for a document association" do
  describe "accepts nested document association attributes" do
    before do
      # Set @owner in the described class
      fail "@owner instance variable required" unless defined? @owner
      
      @described_class_factory = described_class.name.gsub(/Controller\z/, '').singularize.underscore.to_sym
      @owner_factory = @owner.class.name.underscore.to_sym
      @example = create @described_class_factory, @owner_factory => @owner
    end
    
    describe "to PUT #update" do
      context "with valid params" do
        before do
          @document_association = create :document_association, document: create(:document, documentable: @owner), associable: @example
        end
        
        it "updates document associations" do
          new_document = create :document, documentable: @owner
          expect {
            put :update, {:id => @example.to_param, @described_class_factory => valid_attributes.merge({
              document_associations_attributes: [
                @document_association.attributes.merge({document_id: new_document.id})
              ]
            }), "#{@owner_factory}_id" => @owner.to_param}
          }.to change{ @document_association.reload.document_id }.to(new_document.id)
        end
      
        it "allows new document associations to be added" do
          expect {
            put :update, {:id => @example.to_param, @described_class_factory => valid_attributes.merge({
              document_associations_attributes: [
                { document_id: create(:document, documentable: @owner) }
              ]
            }), "#{@owner_factory}_id" => @owner.to_param}
          }.to change(DocumentAssociation, :count).by(1)
        end
      
        it "allows document associations to be destroyed" do
          expect {
            put :update, {:id => @example.to_param, @described_class_factory => valid_attributes.merge({
              document_associations_attributes: [
                @document_association.attributes.merge({:_destroy => "1"})
              ]
            }), "#{@owner_factory}_id" => @owner.to_param}
          }.to change(DocumentAssociation, :count).by(-1)
        end
      end
    end

    describe "to POST #create" do
      context "with valid params" do
        it "creates new document associations" do
          expect {
            post :create, {@described_class_factory => valid_attributes.merge({
              document_associations_attributes: [
                { document_id: create(:document, documentable: @owner) }
              ]
            }), "#{@owner_factory}_id" => @owner.to_param}
          }.to change(DocumentAssociation, :count).by(1)
        end
      
        it "rejects document associations with blank document ids" do
          expect {
            post :create, {@described_class_factory => valid_attributes.merge({
              document_associations_attributes: [
                { document_id: create(:document, documentable: @owner) },
                { document_id: nil }
              ]
            }), "#{@owner_factory}_id" => @owner.to_param}
          }.to change(DocumentAssociation, :count).by(1)
        end
      end
    end
  end
end

# For feature specs
RSpec.shared_examples "it accepts nested attributes for document associations" do
  describe "via a nested form" do
    before do
      # Set @owner in the described class
      fail "@owner instance variable required" unless defined? @owner
      fail "@example instance variable required" unless defined? @example

      @example_class = @example.class.name.underscore.to_sym
    end
    
    describe "with uploaded documents" do
      before do
        @document_1 = create :document, documentable: @owner
        @document_2 = create :document, documentable: @owner
      end
      
      describe "to GET /owner_path/:owner_id/example_path/new" do
        before do
          # Need to explicitly pass in :locale param to avoid UrlGenerationError
          visit new_polymorphic_path([@owner, @example_class], locale: :en)
        end
    
        it "shows a table of document associations" do
          expect(page).to have_selector "table#document-associations"
        end
    
        it "shows at least one set of nested form elements for selecting documents to associate" do
          within "#document-associations .fields select" do
            expect(page).to have_selector "option", text: @document_1.description
            expect(page).to have_selector "option", text: @document_2.description
          end
        end
    
        it "shows a link to add document associations" do
          expect(page).to have_selector "a.add_nested_fields", text: "Add associated document"
        end
          
        # TODO Pending acceptance and merge of capybara_js branch into develop
        skip "allows new associations to be added", js: true
      end

      describe "to GET /owner_path/:owner_id/example_path/:id/edit" do
        before do
          create :document_association, document: @document_1, associable: @example

          # Need to explicitly pass in :locale param to avoid UrlGenerationError
          visit edit_polymorphic_path([@owner, @example], locale: :en)
        end      
    
        it "shows previously associated documents" do
          expect(page).to have_selector "#document-associations select option[selected=\"selected\"]", text: @document_1.description
        end
    
        it "shows at least one new set of nested form elements" do
          expect(all("#document-associations .fields select").size).to eq 2
        end

        it "allows existing associations to be edited" do
          expect(@example.document_associations(true).first.document).to eq @document_1
          within first("#document-associations .fields") do
            find("select option[value=\"#{@document_2.id}\"]").select_option
          end
          click_button "Save"
          expect(@example.document_associations(true).first.document).to eq @document_2
        end

        it "shows a link to add document associations" do
          expect(page).to have_selector "a.add_nested_fields", text: "Add associated document"
        end
          
        it "shows a link to remove existing document associations" do
          within first("#document-associations .fields") do
            expect(page).to have_selector "a.remove_nested_fields", text: "X"
          end
        end
          
        # TODO Pending acceptance and merge of capybara_js branch into develop
        skip "allows new associations to be added", js: true
    
        # TODO Pending acceptance and merge of capybara_js branch into develop
        skip "allows existing associations to be removed", js: true
      end
    end
  
    describe "without uploaded documents" do
      describe "to GET /owner_path/:owner_id/example_path/new without uploaded documents" do
        before do
          # Need to explicitly pass in :locale param to avoid UrlGenerationError
          visit new_polymorphic_path([@owner, @example_class], locale: :en)
        end

        it "shows a message instead of form elements if no documents have been uploaded" do
          within "#document-associations" do
            expect(page).to have_text "No documents have been uploaded yet"
          end
        end
    
        it "does not show a link to add document associations when no documents have been uploaded" do
          expect(page).not_to have_link "Add associated document"
        end
      end

      describe "to GET /owner_path/:owner_id/example_path/:id/edit" do
        before do
          # Need to explicitly pass in :locale param to avoid UrlGenerationError
          visit edit_polymorphic_path([@owner, @example], locale: :en)
        end

        it "shows a message instead of form elements if no documents have been uploaded" do
          within "#document-associations" do
            expect(page).to have_text "No documents have been uploaded yet"
          end
        end
    
        it "does not show a link to add document associations when no documents have been uploaded" do
          expect(page).not_to have_link "Add associated document"
        end
      end
    end
  end
end
