class Document < ActiveRecord::Base
  belongs_to :documentable, polymorphic: true, inverse_of: :documents
  has_many :document_associations, inverse_of: :document, dependent: :destroy
  
  has_attached_file :document

  validates :description, presence: true
  validates :documentable, presence: true, associated: true
  validates_attachment :document, presence: true,
    content_type: { :content_type => [
      "image/jpeg", "image/gif", "image/png", # image files (.png, .gif, .jpg)
      "text/plain",                           # plain text files (.txt)
      "application/pdf",                      # PDF (.pdf)
      
      # MS Excel (.xls, .xlsx)
      "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      
      # MS Word (.doc, .docx)
      "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ]},
    :size => { :in => 0..2.gigabytes }
          
  scope :default_order, -> { order(description: :asc) }
end
