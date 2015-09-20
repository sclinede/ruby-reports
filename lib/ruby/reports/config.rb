require 'ostruct'

module Ruby
  module Reports
    class Config < OpenStruct
      BATCH_SIZE = 10_000
      DEFAULT_EXPIRE_TIME = 86_400
      DEFAULT_CODING = 'utf-8'.freeze
      DEFAULT_CSV_OPTIONS = {col_sep: ';', row_sep: "\r\n"}

      def initialize(*args)
        super
        self.batch_size ||= BATCH_SIZE
        self.encoding ||= DEFAULT_CODING
        self.expire_in ||= DEFAULT_EXPIRE_TIME
        self.csv_options ||= DEFAULT_CSV_OPTIONS
      end
    end
  end
end
