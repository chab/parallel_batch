# encoding: utf-8

require 'test_helper'

class ParallelBatchTest < ActiveSupport::TestCase
  # Sample batch for testing purposes
  class SampleBatch < ParallelBatch
    def perform(record)
      record.name.upcase! and record.save!
    end
  end

  def test_find_or_create_when_batch_does_not_exist
    ParallelBatch.expects(:first => nil)
    ParallelBatch.expects(:create! => batch = ParallelBatch.new)
    assert_equal(batch, ParallelBatch.find_or_create!)
  end

  def test_find_or_create_when_batch_already_present
    ParallelBatch.expects(:first => batch = ParallelBatch.new)
    ParallelBatch.expects(:create!).never
    assert_equal(batch, ParallelBatch.find_or_create!)
  end

  def test_find_records
    (scope = mock).expects(:where).with('id > ?', 2000).returns(where = mock)
    where.expects(:order).with(:id).returns(order = mock)
    order.expects(:limit).with(1000).returns([1, 2, 3])
    batch = ParallelBatch.new(offset: 2000)
    batch.expects(scope: scope)
    assert_equal([1, 2, 3], batch.find_records)
  end

  def test_next_batch
    batch = SampleBatch.new
    batch.expects(:reload).with(:lock => true)
    batch.expects(:find_records => records = [stub(:id => 123)])
    batch.expects(:update_attributes!).with(:offset => 123)
    assert_equal(records, batch.next_batch)
  end

  def test_run
    batch = SampleBatch.new
    batch.expects(:perform).with(u = User.new)
    batch.expects(:next_batch => [u]).in_sequence(run = sequence('run'))
    batch.expects(:next_batch => nil).in_sequence(run)
    batch.run
  end
end