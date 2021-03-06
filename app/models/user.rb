class User < ApplicationRecord
  validates :username, :password_digest, :session_token, :name, presence: true
  validates :username, uniqueness: true
  validates :password, length: { minimum: 6, allow_nil: true }

  has_attached_file :avatar, default_url: "default-avatar-img.png", s3_protocol: :https
  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\z/

  attr_reader :password

  after_initialize :ensure_session_token

  has_many :stories,
    class_name: 'Story',
    foreign_key: :author_id

  def self.find_by_credentials(username, password)
    user = User.find_by(username: username)
    user && user.is_password?(password) ? user : nil
  end

  def password=(password)
    @password = password
    self.password_digest = BCrypt::Password.create(password)
  end

  def is_password?(password)
    BCrypt::Password.new(self.password_digest).is_password?(password)
  end

  def reset_session_token!
    generate_session_token
    save!
    self.session_token
  end

  private
  def ensure_session_token
    generate_session_token unless self.session_token
  end

  def new_session_token
    SecureRandom.urlsafe_base64
  end

  def generate_session_token
    self.session_token = new_session_token
    while User.find_by(session_token: self.session_token)
      self.session_token = new_session_token
    end
    self.session_token
  end
end
