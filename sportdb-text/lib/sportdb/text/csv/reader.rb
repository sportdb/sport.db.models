# encoding: utf-8


module SportDb
class CsvMatchReader


##  todo/fix: use a generic "global" parse_csv method - why? why not?
## def self.parse_csv( text, sep: ',' )    ## helper -lets you change the csv library in one place if needed/desired
##   ## note:  do NOT symbolize keys - keep them as is!!!!!!
##  ##   todo/fix: move "upstream" and remove symbolize keys too!!! - why? why not?
##   CsvHash.parse( text, sep: sep )
## end

def self.read( path, headers: nil, filters: nil, converters: nil, sep: ',' )
   text = File.open( path, 'r:utf-8' ) {|f| f.read }   ## note: make sure to use (assume) utf-8
   parse( text, headers: headers,
                filters: filters,
                converters: converters,
                sep: sep )
end

def self.parse( text, headers: nil, filters: nil, converters: nil, sep: ',' )
   new( text ).parse( headers: headers,
                      filters: filters,
                      converters: converters,
                      sep: sep )
end

def initialize( text )
  @text = text
end

def parse( headers: nil, filters: nil, converters: nil, sep: ',' )

  headers_mapping = {}

  rows = CsvHash.parse( @text, sep: sep )

  return []   if rows.empty?      ## no rows / empty?


  ## fix/todo: use logger!!!!
  ## pp csv

  if headers   ## use user supplied headers if present
    headers_mapping = headers_mapping.merge( headers )
  else

    ## note: returns an array of strings (header names)  - assume all rows have the same columns/fields!!!
    headers = rows[0].keys
    pp headers

    # note: greece 2001-02 etc. use HT  -  check CVS reader  row['HomeTeam'] may not be nil but an empty string?
    #   e.g. row['HomeTeam'] || row['HT'] will NOT work for now

    if find_header( headers, ['Team 1']) && find_header( headers, ['Team 2'])
       ## assume our own football.csv format, see github.com/footballcsv
       headers_mapping[:team1]  = find_header( headers, ['Team 1'] )
       headers_mapping[:team2]  = find_header( headers, ['Team 2'] )
       headers_mapping[:date]   = find_header( headers, ['Date'] )

       ## check for all-in-one full time (ft) and half time (ht9 scores?
       headers_mapping[:score]  = find_header( headers, ['FT'] )
       headers_mapping[:scorei] = find_header( headers, ['HT'] )

       headers_mapping[:round]  = find_header( headers, ['Round'] )

       ## optional headers - note: find_header returns nil if header NOT found
       header_stage = find_header( headers, ['Stage'] )
       headers_mapping[:stage]  =  header_stage   if header_stage
    else
       ## else try footballdata.uk and others
       headers_mapping[:team1]  = find_header( headers, ['HomeTeam', 'HT', 'Home'] )
       headers_mapping[:team2]  = find_header( headers, ['AwayTeam', 'AT', 'Away'] )
       headers_mapping[:date]   = find_header( headers, ['Date'] )

       ## note: FT = Full Time, HG = Home Goal, AG = Away Goal
       headers_mapping[:score1] = find_header( headers, ['FTHG', 'HG'] )
       headers_mapping[:score2] = find_header( headers, ['FTAG', 'AG'] )

       ## check for half time scores ?
       ##  note: HT = Half Time
       headers_mapping[:score1i] = find_header( headers, ['HTHG'] )
       headers_mapping[:score2i] = find_header( headers, ['HTAG'] )
    end
  end

  pp headers_mapping

  ### todo/fix: check headers - how?
  ##  if present HomeTeam or HT required etc.
  ##   issue error/warn is not present
  ##
  ## puts "*** !!! wrong (unknown) headers format; cannot continue; fix it; sorry"
  ##    exit 1
  ##

  matches = []

  rows.each_with_index do |row,i|

    ## fix/todo: use logger!!!!
    ## puts "[#{i}] " + row.inspect  if i < 2


    ## todo/fix: move to its own (helper) method - filter or such!!!!
     if filters    ## filter MUST match if present e.g. row['Season'] == '2017/2018'
       skip = false
       filters.each do |header, value|
         if row[ header ] != value   ## e.g. row['Season']
           skip = true
           break
         end
       end
       next if skip   ## if header values NOT matching
     end


    ## note:
    ##   add converters after filters for now (why not before filters?)
    if converters   ## any converters defined?
      ## convert single proc shortcut to array with single converter
      converters = [converters]    if converters.is_a?( Proc )

      ## assumes array of procs
      converters.each do |converter|
        row = converter.call( row )
      end
    end



    team1 = row[ headers_mapping[ :team1 ]]
    team2 = row[ headers_mapping[ :team2 ]]


    ## check if data present - if not skip (might be empty row)
    if team1.nil? && team2.nil?
      puts "*** WARN: skipping empty? row[#{i}] - no teams found:"
      pp row
      next
    end

    ## remove possible match played counters e.g. (4) (11) etc.
    team1 = team1.sub( /\(\d+\)/, '' ).strip
    team2 = team2.sub( /\(\d+\)/, '' ).strip



    col = row[ headers_mapping[ :date ]]
    col = col.strip   # make sure not leading or trailing spaces left over

    if col.empty? || col == '-' || col == '?'
       ## note: allow missing / unknown date for match
       date = nil
    else
      ## remove possible weekday or weeknumber  e.g. (Fri) (4) etc.
      col = col.sub( /\(W?\d{1,2}\)/, '' )  ## e.g. (W11), (4), (21) etc.
      col = col.sub( /\(\w+\)/, '' )  ## e.g. (Fri), (Fr) etc.
      col = col.strip   # make sure not leading or trailing spaces left over

      if col =~ /^\d{2}\/\d{2}\/\d{4}$/
        date_fmt = '%d/%m/%Y'   # e.g. 17/08/2002
      elsif col =~ /^\d{2}\/\d{2}\/\d{2}$/
        date_fmt = '%d/%m/%y'   # e.g. 17/08/02
      elsif col =~ /^\d{4}-\d{2}-\d{2}$/      ## "standard" / default date format
        date_fmt = '%Y-%m-%d'   # e.g. 1995-08-04
      elsif col =~ /^\d{1,2} \w{3} \d{4}$/
        date_fmt = '%d %b %Y'   # e.g. 8 Jul 2017
      else
        puts "*** !!! wrong (unknown) date format >>#{col}<<; cannot continue; fix it; sorry"
        ## todo/fix: add to errors/warns list - why? why not?
        exit 1
      end

      ## todo/check: use date object (keep string?) - why? why not?
      ##  todo/fix: yes!! use date object!!!! do NOT use string
      date = Date.strptime( col, date_fmt ).strftime( '%Y-%m-%d' )
    end


    round   = nil
    ## check for (optional) round / matchday
    if headers_mapping[ :round ]
      col = row[ headers_mapping[ :round ]]
      ## todo: issue warning if not ? or - (and just empty string) why? why not
      round = col.to_i  if col =~ /^\d{1,2}$/     # check format - e.g. ignore ? or - or such non-numbers for now
    end


    score1  = nil
    score2  = nil
    score1i = nil
    score2i = nil

    ## check for full time scores ?
    if headers_mapping[ :score1 ] && headers_mapping[ :score2 ]
      ft = [ row[ headers_mapping[ :score1 ]],
             row[ headers_mapping[ :score2 ]] ]

      ## todo/fix: issue warning if not ? or - (and just empty string) why? why not
      score1 = ft[0].to_i  if ft[0] =~ /^\d{1,2}$/
      score2 = ft[1].to_i  if ft[1] =~ /^\d{1,2}$/
    end

    ## check for half time scores ?
    if headers_mapping[ :score1i ] && headers_mapping[ :score2i ]
      ht = [ row[ headers_mapping[ :score1i ]],
             row[ headers_mapping[ :score2i ]] ]

      ## todo/fix: issue warning if not ? or - (and just empty string) why? why not
      score1i = ht[0].to_i  if ht[0] =~ /^\d{1,2}$/
      score2i = ht[1].to_i  if ht[1] =~ /^\d{1,2}$/
    end

    ## check for all-in-one full time scores?
    if headers_mapping[ :score ]
      ft = row[ headers_mapping[ :score ] ]
      if ft =~ /^\d{1,2}[\-:]\d{1,2}$/   ## sanity check scores format
        scores = ft.split( /[\-:]/ )
        score1 = scores[0].to_i
        score2 = scores[1].to_i
      end
      ## todo/fix: issue warning if non-empty!!! and not matching format!!!!
    end

    if headers_mapping[ :scorei ]
      ht = row[ headers_mapping[ :scorei ] ]
      if ht =~ /^\d{1,2}[\-:]\d{1,2}$/   ## sanity check scores format
        scores = ht.split( /[\-:]/)   ## allow 1-1 and 1:1
        score1i = scores[0].to_i
        score2i = scores[1].to_i
      end
      ## todo/fix: issue warning if non-empty!!! and not matching format!!!!
    end


    ## try some optional headings / columns
    stage = nil
    if headers_mapping[ :stage ]
      col = row[ headers_mapping[ :stage ]]
      ## todo/fix: check can col be nil e.g. col.nil? possible?
      stage =  if col.nil? || col.empty? || col == '-' || col == 'n/a'
                  ## note: allow missing stage for match / defaults to "regular"
                  nil
               elsif col == '?'
                   ## note: default explicit unknown to unknown for now AND not regular - why? why not?
                  '?'   ## todo/check: use unkown and NOT ?  - why? why not?
               else
                  col
               end
    end


    match = Import::Match.new( date:    date,
                               team1:   team1,   team2:   team2,
                               score1:  score1,  score2:  score2,
                               score1i: score1i, score2i: score2i,
                               round:   round,
                               stage:   stage )
    matches << match
  end

  ## pp matches
  matches
end


private

def find_header( headers, candidates )
   ## todo/fix: use find_first from enumare of similar ?! - why? more idiomatic code?

  candidates.each do |candidate|
     return candidate   if headers.include?( candidate ) ## bingo!!!
  end
  nil  ## no matching header  found!!!
end

end # class CsvReader
end # module SportDb

