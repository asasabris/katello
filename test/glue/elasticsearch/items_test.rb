#
# Copyright 2014 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

require 'katello_test_helper'

module Katello
  class GlueElasticSearchTest < ActiveSupport::TestCase
    def setup
      @fake_class = Class.new do
        def self.search
        end

        def self.where(*_args)
        end

        def self.mapping(*_args)
          {}
        end
      end

      @results = MiniTest::Mock.new
      @results.expect(:class, 0)
      @results.expect(:empty?, true)

      @items = Glue::ElasticSearch::Items.new(@fake_class)
    end

    def test_items
      @results.expect(:total, 0)
      @results.expect(:total, 0)
      @results.expect(:subtotal, 0)
      @results.expect(:results, [])
      @results.expect(:facets, {})

      @fake_class.stub(:search, @results) do
        items, count = @items.retrieve("*")

        assert_empty items
        assert_equal 0, count
      end
    end

    def test_load_records
      @results.expect(:length, 0)
      @results.expect(:order, [], [[]])

      @fake_class.stub(:where, @results) do
        @items.results = []
        items = @items.load_records

        assert_empty items
      end
    end

    def test_total_items
      @results.expect(:total, 10)

      @fake_class.stub(:search, @results) do
        total = @items.total_items

        assert_equal 10, total
      end
    end
  end
end
