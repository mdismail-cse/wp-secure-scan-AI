class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :scans, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :vulnerabilities, through: :scans

  def admin?
    admin
  end
end
