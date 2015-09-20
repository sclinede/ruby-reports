# coding: utf-8
# Resque namespace
module Ruby
  # Resque::Reports namespace
  module Reports
    # Class describes base report class for inheritance.
    # BaseReport successor must implement "write(io, force)" method
    # and may specify file extension with "extension" method call
    # example:
    #
    #   class CustomTypeReport < Resque::Reports::BaseReport
    #     extension :type # specify that report file must ends
    #                     # with '.type', e.g. 'abc.type'
    #
    #     # Method specifies how to output report data
    #     def write(io, force)
    #       io << 'Hello World!'
    #     end
    #   end
    #
    # BaseReport provides following DSL, example:
    #
    #   class CustomReport < CustomTypeReport
    #     # include Resque::Reports::Common::BatchedReport
    #     #   overrides data retrieving to achieve batching
    #     #   if included 'source :select_data' becomes needless
    #
    #     queue :custom_reports # Resque queue name
    #     source :select_data # method called to retrieve report data
    #     encoding UTF8 # file encoding
    #     expire_in 86_400 # cache time of the file, default: 86_400
    #
    #     # Specify in which directory to keep this type files
    #     directory File.join(Dir.tmpdir, 'resque-reports')
    #
    #     # Describe table using 'column' method
    #     table do |element|
    #       column 'Column 1 Header', :decorate_one
    #       column 'Column 2 Header', decorate_two(element[1])
    #       column 'Column 3 Header', 'Column 3 Cell'
    #       column 'Column 4 Header', :formatted_four, formatter: :just_cute
    #     end
    #
    #     # Class initialize if needed
    #     # NOTE: must be used instead of define 'initialize' method
    #     # Default behaviour is to receive in *args Hash with report attributes
    #     # like: CustomReport.new(main_param: 'value') => calls send(:main_param=, 'value')
    #     create do |param|
    #       @main_param = param
    #     end
    #
    #     def self.just_cute_formatter(column_value)
    #       "I'm so cute #{column_value}"
    #     end
    #
    #     # decorate method, called by symbol-name
    #     def decorate_one(element)
    #       "decorate_one: #{element[0]}"
    #     end
    #
    #     # decorate method, called directly when filling cell
    #     def decorate_two(text)
    #       "decorate_two: #{text}"
    #     end
    #
    #     # method returns report data Enumerable
    #     def select_data
    #       [[0, 'text0'], [1, 'text1']]
    #     end
    #   end
    class BaseReport
      extend Forwardable

      class << self
        attr_reader :config_hash, :table_block, :progress_handle_block, :error_handle_block

        def config(hash)
          @config_hash = hash
        end

        def table(&block)
          @table_block = block
        end

        def build(options = {})
          force = options.delete(:force)

          report = new(options)
          report.build(force)

          report
        end
      end

      attr_reader :args, :job_id, :events_handler
      def_delegators :cache_file, :filename, :exists?, :ready?

      #--
      # Public instance methods
      #++

      def initialize(*args)
        @args = args
      end

      # Builds report synchronously
      def build(force = false)
        @table = nil if force
        @events_handler = Services::EventsHandler.new(@progress_handle_block, @error_handle_block)

        cache_file.open(force) { |file| write(file, force) }
      end

      def progress_handler(&block)
        @progress_handle_block = block
      end

      def error_handler(&block)
        @error_handle_block = block
      end

      def formatter
        nil
      end

      private

      def query
        # descendant of QueryBuilder or SqlQuery with #take_batch(limit, offset) method defined
        # @query ||= Query.new(self)
        fail NotImplementedError
      end

      def iterator
        @iterator ||= Services::DataIterator.new(query, config)
      end

      def config
        @config ||= Config.new(self.class.config_hash)
      end

      def table
        @table ||= Services::TableBuilder.new(self, self.class.table_block, config)
      end

      def cache_file
        @cache_file ||= CacheFile.new(config.directory,
                                      Services::FilenameGenerator.generate(args, config.extension),
                                      expire_in: config.expire_in, coding: config.encoding)
      end

      # Method specifies how to output report data
      # @param [IO] io stream for output
      # @param [true, false] force write to output or skip due its existance
      def write(io, force)
        # You must use ancestor methods to work with report data:
        # 1) iterator.data_size => returns source data size (calls #count on data
        #                 retrieved from 'source')
        # 2) iterator.data_each => yields given block for each source data element
        # 3) table.build_header => returns Array of report column names
        # 4) table.build_row(object) => returns Array of report cell
        #                               values (same order as header)
        # 5) events_handler.progress(progress, total) => call to iterate job progress
        # 6) events_handler.error(error) => call to handle error in job
        #
        # HINT: You may override data_size and data_each, to retrieve them
        #       effectively
        fail NotImplementedError
      end
    end # class BaseReport
  end # module Report
end # module Resque
