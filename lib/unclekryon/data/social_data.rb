# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2018-2021 Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++


##
# This should NOT extend BaseData/etc. It is basically just a container/struct.
##
module UncleKryon
  class SocialData
    attr_accessor :username
    attr_accessor :url

    def initialize
      super()

      @username = ''
      @url = ''
    end
  end
end
