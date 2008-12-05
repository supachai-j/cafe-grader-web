require 'digest/sha1'

class User < ActiveRecord::Base

  has_and_belongs_to_many :roles

  has_many :test_requests, :order => "submitted_at DESC"

  has_many :messages, 
           :class_name => "Message",
           :foreign_key => "sender_id", 
           :order => 'created_at DESC'

  has_many :replied_messages, 
           :class_name => "Message",
           :foreign_key => "receiver_id", 
           :order => 'created_at DESC'

  belongs_to :site
  belongs_to :country

  validates_presence_of :login
  validates_presence_of :full_name
  validates_length_of :full_name, :minimum => 1
  
  validates_presence_of :password, :if => :password_required?
  validates_length_of :password, :within => 4..20, :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?

  attr_accessor :password

  before_save :encrypt_new_password

  def self.authenticate(login, password)
    user = find_by_login(login)
    return user if user && user.authenticated?(password)
  end

  def authenticated?(password)
    if self.activated
      hashed_password == User.encrypt(password,self.salt)
    else
      false
    end
  end

  def admin?
    self.roles.detect {|r| r.name == 'admin' }
  end

  def email_for_editing
    if self.email==nil
      "(unknown)"
    elsif self.email==''
      "(blank)"
    else
      self.email
    end
  end

  def email_for_editing=(e)
    self.email=e
  end

  def alias_for_editing
    if self.alias==nil
      "(unknown)"
    elsif self.alias==''
      "(blank)"
    else
      self.alias
    end
  end

  def alias_for_editing=(e)
    self.alias=e
  end

  def activation_key
    Digest::SHA1.hexdigest(self.hashed_password)[0..7]
  end

  def verify_activation_key(key)
    key == activation_key
  end

  protected
    def encrypt_new_password
      return if password.blank?
      self.salt = (10+rand(90)).to_s
      self.hashed_password = User.encrypt(self.password,self.salt)
    end
  
    def password_required?
      self.hashed_password.blank? || !self.password.blank?
    end
  
    def self.encrypt(string,salt)
      Digest::SHA1.hexdigest(salt + string)
    end
end
