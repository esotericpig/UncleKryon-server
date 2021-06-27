#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2018-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++


require 'date'

require 'unclekryon/util'

module UncleKryon
  class BaseData
    attr_accessor :updated_on

    def initialize()
      update()
    end

    def initialize_copy(original)
      super(original)

      @updated_on = @updated_on.clone()
    end

    def update()
      @updated_on = Util.format_datetime(DateTime.now())
      return @updated_on
    end

    def max_updated_on()
      max = nil

      instance_variables.each do |iv|
        vuo = Util.parse_datetime_s(instance_variable_get(iv)) if iv.to_s() =~ /\A@updated_.+_on\z/
        max = vuo if max.nil?() || vuo > max
      end

      return max
    end

    def self.max_updated_on(data)
      max = nil

      if data.is_a?(Hash)
        data.each() do |k,v|
          vuo = Util.parse_datetime_s(v.updated_on)
          max = vuo if max.nil?() || vuo > max
        end
      end

      return max
    end

    def max_updated_on_s()
      return Util.format_datetime(max_updated_on())
    end

    def self.max_updated_on_s(data)
      return Util.format_datetime(max_updated_on(data))
    end
  end
end
