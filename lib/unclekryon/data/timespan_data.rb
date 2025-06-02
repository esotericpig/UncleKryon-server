# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2021 Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++


##
# This is for parsing/formatting mp3/etc. duration data.
# This should NOT extend BaseData/etc. It is basically just a String Util class.
##
module UncleKryon
  class TimespanData
    attr_accessor :hours
    attr_accessor :mins
    attr_accessor :secs

    def initialize(time=nil)
      @hours = 0
      @mins = 0
      @secs = 0

      if !time.nil? && !(time = time.strip).empty?
        time = time.gsub(/\A[^\(]+\(/,'') # "One hour 6 minutes - (66 minutes)"
        time = time.gsub(/[^[[:digit:]]\:\.]+/,'')
        a = time.split(/[\:\.]/)

        if a.length == 1
          @mins = a[0].to_i
        elsif a.length == 2
          @mins = a[0].to_i
          @secs = a[1].to_i
        elsif a.length >= 3
          @hours = a[0].to_i
          @mins = a[1].to_i
          @secs = a[2].to_i
        end

        if @secs >= 60
          @mins += (@secs / 60)
          @secs = @secs % 60
        end
        if @mins >= 60
          @hours += (@mins / 60)
          @mins = @mins % 60
        end
      end
    end

    def to_s
      return "#{@hours}:#{@mins}:#{@secs}"
    end
  end
end
