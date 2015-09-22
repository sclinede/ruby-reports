module Ruby
  module Reports
    module Services
      class DataIterator
        attr_reader :custom_source
        pattr_initialize :query, :config do
          @custom_source = query.send(config.source) if config.source
        end

        def iterate_custom_source
          custom_source.each do |row|
            yield row
          end
        end
        # Internal: Выполняет запрос строк отчета пачками
        #
        # Returns Nothing
        def data_each(force = false, &block)
          return iterate_custom_source(&block) if custom_source

          batch_offset = 0

          while (rows = query.request_batch(batch_offset)).count > 0 do
            rows.each { |row| yield row }
            batch_offset += config.batch_size
          end
        end

        # Internal: Возвращает общее кол-во строк в отчете
        #
        # Returns Fixnum
        def data_size
          @data_size ||= if custom_source
                           custom_source.count
                         else
                           query.request_count
                         end
        end
      end
    end
  end
end
