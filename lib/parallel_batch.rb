# encoding: utf-8

class ParallelBatch < ActiveRecord::Base

  #################
  ### Constants ###
  #################

  VERSION = "0.0.1"

  #####################
  ### Class methods ###
  #####################

  def self.find_or_create!
    first || create!(offset: 0)
  # When starting many batches at the same time we are pretty sure to get a MySQL
  # error reporting a duplicated entry. That's why we are retrying one time only.
  rescue ActiveRecord::StatementInvalid
    first || create!(offset: 0)
  end

  def self.start(concurrency = 1)
    concurrency.times { fork { start_fork } }
  end

  def self.start_fork
    puts "#{self} has started with pid #{Process.pid}"
    ActiveRecord::Base.connection.reconnect!
    find_or_create!.run
  end

  def self.reset
    find_or_create!.update_attributes!(offset: null)
  end

  ########################
  ### Instance methods ###
  ########################

  def find_records
    offset ? scope.where('id > ?', offset).order(:id).limit(batch_size) : scope.order(:id).limit(batch_size)
  end

  def next_batch
    transaction do
      reload(lock: true)
      next unless (records = find_records).last
      update_attributes!(offset: records.last.id)
      records
    end
  end

  def run
    while records = next_batch
      records.each { |record| perform(record) }
    end
  end

  def perfom(record)
    raise NotImplementedError, 'You must override this method to perform your batch.'
  end

  def scope
    raise NotImplementedError, 'You must override this method to scope your records.'
  end

  def batch_size
    1000
  end
  
end
