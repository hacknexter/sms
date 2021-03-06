class TelephoneNumber < ActiveRecord::Base
  extend ActiveSupport::Memoizable

  belongs_to :user
  belongs_to :contact
  has_and_belongs_to_many :messages

  validates_presence_of :user
  validates_presence_of :country_code, :message => "is blank or invalid", :if => :number_valid?
  validates_presence_of :subscriber_number, :if => :number_valid?
  validates_uniqueness_of :subscriber_number, :scope => [:country_code, :user_id], :message => "is already in database"

  attr_writer :number
  @@per_page = 8
  cattr_reader :per_page

  attr_accessible :number, :description

  before_validation :split_number
  before_destroy :destroyable?

  def number
    @number or joined_number
  end
  memoize :number

  def to_s
    contact ? contact.name : number
  end

  def self.find_by_contact_name(name)
    contact = Contact.find_by_name(name)
    contact ? contact.telephone_number : nil
  end

  def validate
    errors.add :number, "#{number} is too long (maximum is 15 digits)" if sanitized_number.size > 16
    errors.add :number, "format is invalid or no contact named #{number}" unless sanitized_number =~ /\A(?:\+\d)?\d+\Z/
  end

  def destroyable?
    contact.blank? and messages.empty?
  end

  protected

  def number_valid?
    E164.is_a_number?(number)
  end

  def sanitized_number
    E164.sanitize_number(number)
  end

  def split_number
    self.country_code, self.subscriber_number = E164.split_number(number, user ? user.default_country_code : "")
  end

  def joined_number
    "#{country_code}#{subscriber_number}"
  end
end
