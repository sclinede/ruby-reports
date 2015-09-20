# coding: utf-8
require 'csv'

module Ruby
  module Reports
    # Class to inherit from for custom CSV reports
    # To make your custom report you must define at least:
    #   1. directory, is where to write reports to
    #   2. source, is symbol of method that retrieves report data
    #   3. table, report table configuration using DSL
    class CsvReport < BaseReport
      attr_reader :csv_options

      def initialize(*args)
        config.extension = :csv
        super
        @csv_options = config.csv_options
      end

      def write(io, force = false)
        # You must use ancestor methods to work with report data:
        #   1) data_size => returns source data size
        #   2) data_each => yields given block for each source data element
        #   3) build_table_header => returns Array of report column names
        #   4) build_table_row(object) => returns Array of report cell values
        #                                 (same order as header)
        progress = 0

        CSV(io, csv_options) do |csv|
          write_line csv, table.build_header

          iterator.data_each(force) do |data_element|
            begin
              write_line csv, table.build_row(data_element)
            rescue
              events_handler.error
            end

            events_handler.progress(progress += 1, iterator.data_size)
          end

          events_handler.progress(progress, iterator.data_size, true)
        end
      end

      def write_line(csv, row_cells)
        csv << row_cells
      end

      #--
      # Event handling #
      #++
      #

      def progress_message(*args)
        'Выгрузка отчета в CSV'
      end

      def error_message(error)
        error_message = []
        error_message << 'Выгрузка отчета невозможна. '
        error_message << case error
                         when Encoding::UndefinedConversionError
                           <<-ERR_MSG.gsub(/^ {29}/, '')
                             Символ #{error.error_char} не поддерживается
                             заданной кодировкой
                           ERR_MSG
                         when EncodingError
                           'Ошибка преобразования в заданную кодировку'
                         else
                           fail error
                         end
        error_message * ' '
      end
    end # class CsvReport
  end # module Report
end # module Ruby
