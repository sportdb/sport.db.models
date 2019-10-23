# encoding: UTF-8


require 'sportdb/config'


## use (switch to) "external" datasets
SportDb::Import.config.clubs_dir   = "../../../openfootball/clubs"
SportDb::Import.config.leagues_dir = "../../../openfootball/leagues"



LEAGUES   = SportDb::Import.config.leagues
CLUBS     = SportDb::Import.config.clubs
COUNTRIES = SportDb::Import.config.countries


require 'sportdb/models'   ## add sql database support

SportDb.connect( adapter: 'sqlite3', database: ':memory:' )
SportDb.create_all   ## build schema

## turn on logging to console
ActiveRecord::Base.logger = Logger.new(STDOUT)



require_relative 'sync'
require_relative 'outline_reader'
require_relative 'event_reader'
require_relative 'match_parser'
require_relative 'match_reader'


path = "../../../openfootball/england/2015-16/.conf.txt"
# path = "../../../openfootball/england/2017-18/.conf.txt"
# path = "../../../openfootball/england/2018-19/.conf.txt"
# path = "../../../openfootball/england/2019-20/.conf.txt"
recs = SportDb::EventReaderV2.read( path )
path = "../../../openfootball/england/2015-16/1-premierleague-i.txt"
# path = "../../../openfootball/england/2017-18/1-premierleague-i.txt"
# path = "../../../openfootball/england/2018-19/1-premierleague.txt"
# path = "../../../openfootball/england/2019-20/1-premierleague.txt"
recs = SportDb::MatchReaderV2.read( path )
# path = "../../../openfootball/england/2017-18/1-premierleague-ii.txt"
#recs = SportDb::MatchReaderV2.read( path )