#!/usr/bin/env ruby

###
# This file is part of UncleKryon-server.
# Copyright (c) 2017 Jonathan Bradley Whited (@esotericpig)
# 
# UncleKryon-server is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# UncleKryon-server is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with UncleKryon-server.  If not, see <http://www.gnu.org/licenses/>.
###

require 'bundler/setup'

require 'unclekryon/hacker'

module UncleKryon
  class Trainer < Hacker
    def initialize(**options)
      # Don't use "()"
      super
    end
    
    def train_kryon_aum_year_album(date,year=nil)
      album_parser = create_kryon_aum_year_album_parser(date,year)
      
      album_parser.train = true
      
      album = album_parser.parse_site()
      
      if @no_clobber
        puts album_parser.trainer_s()
      else
        album_parser.save_trainer()
      end
    end
  end
end

if $0 == __FILE__
  trainer = UncleKryon::Trainer.new(no_clobber: true)
  
  puts trainer.no_clobber
  puts trainer.replace
  puts trainer.train_dirname
  puts trainer.train_kryon_filename
  
  trainer.train_kryon_aum_year_album('2.2','2017')
end
