require 'rails_helper'

RSpec.describe Document, type: :model do
  it "requires a description" do
    document = build :document, description: nil
    expect(document.valid?).to be_falsey
    expect(document.errors.keys).to include :description

    document.description = "Test"
    expect(document.valid?).to be_truthy
  end

  it "requires an associated documentable object" do
    document = build :document, documentable: nil
    expect(document.valid?).to be_falsey
    expect(document.errors.keys).to include :documentable

    document.documentable = create :driver
    expect(document.valid?).to be_truthy
  end

  it "requires a document to be attached" do
    document = build :document, :no_attachment
    expect(document.valid?).to be_falsey
    expect(document.errors.keys).to include :document

    document.document_file_name = 'test.pdf'
    document.document_content_type = 'application/pdf'
    document.document_file_size = 1024
    expect(document.valid?).to be_truthy
  end
  
  describe "attached documents" do
    it "allows image files (.png, .gif, .jpg)" do
      document = build :document, document_content_type: 'image/bmp'
      expect(document.valid?).to be_falsey
      expect(document.errors.keys).to include :document

      %w(image/jpeg image/gif image/png).each do |mime_type|
        document.document_content_type = mime_type
        expect(document.valid?).to be_truthy
      end
    end
    
    it "allows plain text files (.txt)" do
      document = build :document, document_content_type: 'text/html'
      expect(document.valid?).to be_falsey
      expect(document.errors.keys).to include :document

      document.document_content_type = 'text/plain'
      expect(document.valid?).to be_truthy
    end
    
    it "allows PDF files (.pdf)" do
      document = build :document, document_content_type: 'application/javascript'
      expect(document.valid?).to be_falsey
      expect(document.errors.keys).to include :document

      document.document_content_type = 'application/pdf'
      expect(document.valid?).to be_truthy
    end
    
    it "allows MS Excel files (.xls, .xlsx)" do
      document = build :document, document_content_type: 'image/bmp'
      expect(document.valid?).to be_falsey
      expect(document.errors.keys).to include :document

      %w(application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet).each do |mime_type|
        document.document_content_type = mime_type
        expect(document.valid?).to be_truthy
      end
    end
    
    it "allows MS Word files (.doc, .docx)" do
      document = build :document, document_content_type: 'image/bmp'
      expect(document.valid?).to be_falsey
      expect(document.errors.keys).to include :document

      %w(application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document).each do |mime_type|
        document.document_content_type = mime_type
        expect(document.valid?).to be_truthy
      end
    end
    
    it "allows file sizes of 2 gigabytes or smaller" do
      document = build :document, document_file_size: 2.1.gigabytes
      expect(document.valid?).to be_falsey
      expect(document.errors.keys).to include :document

      document.document_file_size = 2.gigabytes
      expect(document.valid?).to be_truthy
    end
  end
  
  describe "document associations" do
    it "has many document associations" do
      expect(Document.reflect_on_association(:document_associations).macro).to  eq :has_many       
    end
    
    it "destroys associated document associations when it is destroyed" do
      document = create :document
      create :document_association, document: document
      create :document_association, document: document
      expect {
        document.destroy
      }.to change(DocumentAssociation, :count).by(-2)
    end
  end
end
