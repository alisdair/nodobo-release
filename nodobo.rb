require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => "#{File.dirname(__FILE__)}/db.sqlite3")

class Call < ActiveRecord::Base
  belongs_to :user
  belongs_to :other, :class_name => "User"
  
  def identity
    @identity ||= [user_id, other_id, number, call_timestamp, duration, direction]
  end
end

class CellTower < ActiveRecord::Base
  belongs_to :user
end

class Device < ActiveRecord::Base
  belongs_to :user
end

class Message < ActiveRecord::Base
  belongs_to :user
  belongs_to :other, :class_name => "User"
  
  def identity
    @identity ||= [user_id, other_id, number, message_timestamp, length, direction]
  end
end

class Presence < ActiveRecord::Base
  belongs_to :user
  belongs_to :other, :class_name => "User"
  
  def at_work?
    work_days = (1..5)
    work_hours = (8..16)
    return (work_days.include?(timestamp.wday) and work_hours.include?(timestamp.hour))
  end
end

Infinity = 1.0/0

class User < ActiveRecord::Base
  has_many :devices
  has_many :messages
  has_many :calls
  has_many :presences
end

class Wifi < ActiveRecord::Base
  belongs_to :user
end
