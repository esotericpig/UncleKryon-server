# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2019-2022 Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++

require 'unclekryon/iso/base_iso'

##
# @see https://en.wikipedia.org/wiki/Subregion
##
module UncleKryon
  class Subregion < BaseIso
  end

  class Subregions < BaseIsos
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/subregions.yaml".freeze

    def self.load_file(filepath = DEFAULT_FILEPATH)
      return Subregions.new.load_file(filepath)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  puts UncleKryon::Subregions.load_file
end
