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
require 'helpers/product_test_data'

module Katello
  describe SyncPlan, :katello => true do
    include OrchestrationHelper

    describe "SyncPlan should" do
      before(:each) do
        @organization = get_organization
        @plan = SyncPlan.create!(:name => 'Norman Rockwell', :organization => @organization, :sync_date => DateTime.now, :interval => 'daily')
      end

      it "be able to create" do
        @plan.wont_be_nil
      end

      it "be able to gracefull handle invalid intervals" do
        @plan.interval = 'notgood'
        @plan.wont_be :valid?
      end

      it "be able to modify valid intervals" do
        @plan.interval = 'weekly'
        @plan.must_be :valid?
      end

      describe "provide the next sync date as" do
        it "the sync date if in the future" do
          sync_date = '5000-11-17 18:26:48 UTC'
          @plan.sync_date = sync_date
          @plan.next_sync.to_s.must_equal(sync_date)
        end

        it "nil if the sync is not enabled" do
          @plan.sync_date = '1999-11-17 18:26:48 UTC'
          @plan.enabled = false
          @plan.next_sync.must_be_nil
        end

        it "nil if the interval is unrecognied" do
          @plan.sync_date = '1999-11-17 18:26:48 UTC'
          @plan.interval = 'blah'
          @plan.next_sync.must_equal(nil)
        end

        it "the next run time if hourly" do
          @plan.interval = 'hourly'
          @plan.sync_date = '1999-11-17 09:26:00 UTC'

          Time.stubs(:now).returns(Time.new(2012, 1, 1, 9))
          @plan.next_sync.must_equal(Time.new(2012, 1, 1, 9, 26, 0, "+00:00"))

          Time.stubs(:now).returns(Time.new(2012, 1, 1, 9, 30))
          @plan.next_sync.must_equal(Time.new(2012, 1, 1, 10, 26, 0, "+00:00"))
        end

        it "the next run time if daily" do
          @plan.interval = 'daily'
          @plan.sync_date = '1999-11-17 09:26:00 UTC'

          Time.stubs(:now).returns(Time.new(2012, 1, 1, 9))
          @plan.next_sync.must_equal(Time.new(2012, 1, 1, 9, 26, 0, "+00:00"))

          Time.stubs(:now).returns(Time.new(2012, 1, 1, 9, 27))
          @plan.next_sync.must_equal(Time.new(2012, 1, 2, 9, 26, 0, "+00:00"))

          Time.stubs(:now).returns(Time.new(2012, 1, 2, 9))
          @plan.next_sync.must_equal(Time.new(2012, 1, 2, 9, 26, 0, "+00:00"))
        end

        it "the next run time if weekly" do
          @plan.interval = 'weekly'
          @plan.sync_date = '1999-11-17 09:26:00 UTC'

          Time.stubs(:now).returns(Time.new(2012, 1, 1, 9))
          @plan.next_sync.must_equal(Time.new(2012, 1, 11, 9, 26, 0, "+00:00"))

          Time.stubs(:now).returns(Time.new(2012, 1, 11, 9, 30))
          @plan.next_sync.must_equal(Time.new(2012, 1, 18, 9, 26, 0, "+00:00"))
        end
      end

      it "be able to update" do
        p = SyncPlan.find_by_name('Norman Rockwell')
        p.wont_be_nil
        new_name = p.name + "N"
        p = SyncPlan.update(p.id, :name => new_name)
        p.name.must_equal(new_name)
      end

      it "be able to delete" do
        p = SyncPlan.find_by_name('Norman Rockwell')
        pid = p.id
        p.destroy

        lambda { SyncPlan.find(pid) }.must_raise(ActiveRecord::RecordNotFound)
      end

      it "should have proper pulp duration format" do
        @plan.interval = 'weekly'
        @plan.schedule_format.wont_be_nil
        @plan.schedule_format.must_match(/\/P7D$/)
      end

      it "should properly handle interval when not enabled" do
        @plan.enabled = false
        @plan.sync_date = DateTime.now.tomorrow
        @plan.schedule_format.wont_be_nil
        @plan.schedule_format.must_match(%r{R1\/.*\/P1D})
      end

      it "should properly handle not being enabled if scheduled in the past" do
        @plan.enabled = false
        @plan.sync_date = DateTime.now.yesterday
        @plan.schedule_format.must_be_nil
      end
    end
  end
end
