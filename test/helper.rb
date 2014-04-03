
## $:.unshift(File.dirname(__FILE__))

## minitest setup

# require 'minitest/unit'
require 'minitest/autorun'

# include MiniTest::Unit  # lets us use TestCase instead of MiniTest::Unit::TestCase


require 'pp'


# ruby gems

require 'active_record'

require 'worlddb'
require 'logutils'
require 'logutils/db'   # NB: explict require required for LogDb (not automatic) 
require 'props/db'   ## fix: use textutils/db in the future too ??


## our own code

require 'sportdb'


#######################
#
#  for reuse
#   --- move to sportdb/test.rb ???
#    SportDb.setup_in_memory_db  ??? why? why not??  or
#    SportDb.setup_test_db  - alias ??



def setup_in_memory_db
  # Database Setup & Config

  db_config = {
    adapter:  'sqlite3',
    database: ':memory:'
  }

  pp db_config

  ActiveRecord::Base.logger = Logger.new( STDOUT )
  ## ActiveRecord::Base.colorize_logging = false  - no longer exists - check new api/config setting?

  ## NB: every connect will create a new empty in memory db
  ActiveRecord::Base.establish_connection( db_config )


  ## build schema

  LogDb.create
  ConfDb.create
  TagDb.create
  WorldDb.create
  SportDb.create
end

####
# Models shortcuts

Game       = SportDb::Model::Game
GameCursor = SportDb::Model::GameCursor



setup_in_memory_db()
