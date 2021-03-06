require 'digest'

class User
  attr :id,:first,:last,:user_name,:email

  include DataMapper::Resource

  property :id,                     Serial
  property :first,                  String, :required => true
  property :last,                   String, :required => true
  property :user_name,              String, :required => true, :unique => true
  property :email,                  String, length: 255
  property :hashed_password,        String, length: 255

  has n, :photos

  def self.login(username, pwd)
    hashed = Digest::SHA256.hexdigest '**123SALTY**' + pwd
    first(user_name: username, hashed_password: hashed)
  end

  def password=(pwd)
    self.hashed_password = Digest::SHA256.hexdigest '**123SALTY**' + pwd
  end

  def get_first(username)
    first
  end

  def get_full_name
    first.capitalize+" "+last.capitalize
  end

  def change_name(full_name)
    self.first = full_name.split[0]
    self.last = full_name.split[1]
  end

  def self.get_db_user(user)
    first(user_name: user)
  end

  def self.get_other_user(username)
    first(user_name: username)
  end

  def get_all_users
    #User.all.map(&:user_name)
    all.map {|user| user }
  end

  def self.get_all_user_names
    all.map {|user| user.user_name }
  end

  def get_all_following_users
    followed_users.map {|user| user }
  end

  def get_all_following_user_names
    followed_users.map {|user| user.user_name }
  end

  def get_all_followed_user_names
    followers.map {|user| user.user_name }
  end

  def get_all_not_following_user_names
    User.get_all_user_names - get_all_following_user_names - [self.user_name]
  end

# The link db object to join users/followers/following
  class Link
    include DataMapper::Resource

    storage_names[:default] = 'users_links'

    belongs_to :follower, 'User', :key => true
    belongs_to :followed, 'User', :key => true
  end
  has n, :links_to_followed_users, 'User::Link', :child_key => [:follower_id]
  has n, :links_to_followers, 'User::Link', :child_key => [:followed_id]
  has n, :followed_users, self, :through => :links_to_followed_users, :via => :followed
  has n, :followers, self, :through => :links_to_followers, :via => :follower

  def follow(others)
    followed_users.concat(Array(others))
    save
    self
  end

  def unfollow(others)
    links_to_followed_users.all(:followed => Array(others)).destroy!
    reload
    self
  end

  def get_followers
    followers
  end
end
