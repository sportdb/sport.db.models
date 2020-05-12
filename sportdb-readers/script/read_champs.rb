##
#  use
#    ruby -I ./lib script/read_champs.rb


require_relative 'boot'


File.delete( './champs.db' )   if File.exist?( './champs.db' )


SportDb.connect( adapter:  'sqlite3',
                 database: './champs.db' )
SportDb.create_all   ## build schema

## turn on logging to console
## ActiveRecord::Base.logger = Logger.new(STDOUT)



path = "#{OPENFOOTBALL_PATH}/europe-champions-league"

pack = SportDb::Package.new( path )
pack.read_match

## pack.read
## pack.read( season: '2012/13' )

puts 'bye'
