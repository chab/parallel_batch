# encoding: utf-8

class ParallelBatch < ActiveRecord::Base

  #####################
  ### Class methods ###
  #####################

  def self.find_or_create!
    first || create!
  # When starting many batches at the same time we are pretty sure to get a MySQL
  # error reporting a duplicated entry. That's why we are retrying one time only.
  rescue ActiveRecord::StatementInvalid
    first || create!
  end

  def self.start(concurrency = 1)
    concurrency.times { Process.detach(fork { start_fork }) }
  end

  def self.start_fork
    puts "#{self} has started with pid #{Process.pid}"
    ActiveRecord::Base.connection.reconnect!
    Process.daemon(false)
    find_or_create!.run
  end

  def self.reset
    find_or_create!.update_attributes!(offset: nil)
  end

  ########################
  ### Instance methods ###
  ########################

  def logger
    @logger ||= Logger.new(Rails.root.join("log", "#{self.class}-#{Rails.env}.log"))
  end

  def log(s)
    logger.info "#{Time.now}: #{s}"
  end

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
    log "== pid #{Process.pid} begin"
    while records = next_batch
      log "== pid #{Process.pid} begin batch: #{records.first.id} -> #{records.last.id}"
      records.each { |record| perform(record) rescue nil }
      log "== pid #{Process.pid} end batch: #{records.first.id} -> #{records.last.id}"
    end
    log "== pid #{Process.pid} end"
  end

  def perfom(record)
    raise NotImplementedError, 'You must override this method to perform your batch.'
  end

  def scope
    raise NotImplementedError, 'You must override this method to scope your records.'
  end

  def batch_size
    100
  end

end
