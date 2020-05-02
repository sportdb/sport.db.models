# encoding: utf-8


## require 'sportdb/leagues'
## require 'sportdb/teams'
require 'sportdb/config'

require 'sportdb/models'   ## add sql database support



###
# our own code
require 'sportdb/sync/version' # let version always go first
require 'sportdb/sync/country'
require 'sportdb/sync/league'
require 'sportdb/sync/season'
require 'sportdb/sync/event'
require 'sportdb/sync/club'
require 'sportdb/sync/sync'


puts SportDb::Sync.banner   # say hello
