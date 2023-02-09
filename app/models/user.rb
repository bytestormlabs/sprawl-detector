class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :lockable, :trackable, :omniauthable

  belongs_to :tenant
  has_many :accounts, through: :tenant
  has_many :findings, through: :accounts

  attr_accessor :authentication_token
end
