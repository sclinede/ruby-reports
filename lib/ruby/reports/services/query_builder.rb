module Ruby
  module Reports
    module Services
      class QueryBuilder
        extend Forwardable
        pattr_initialize :report, :config

        def request_count
          execute(count)[0]['count'].to_i
        end

        def request_batch(offset)
          execute take_batch(config.batch_size, offset)
        end

        private

        def_delegator :connection, :execute

        def connection
          ActiveRecord::Base.connection
        end

        # Internal: Возвращает отфильтрованный запрос отчета
        #
        # Returns Arel::SelectManager
        def query
          filter base_query
        end

        # Internal: Полезный метод для хранения Arel::Table объектов для запроса отчета
        #
        # Returns Hash, {:table_name => #<Arel::Table @name="table_name">, ...}
        def tables
          return @tables if defined? @tables

          tables = models.map(&:arel_table)

          @tables = tables.reduce({}) { |a, e| a.store(e.name, e) && a }.with_indifferent_access
        end

        # Internal: Полезный метод для join'а необходимых таблиц через Arel
        #
        # Returns Arel
        def join_tables(source_table, *joins)
          joins.inject(source_table) { |query, joined| query.join(joined[:table]).on(joined[:on]) }
        end

        # Internal: Размер пачки отчета
        #
        # Returns Fixnum
        def batch_size
          BATCH_SIZE
        end

        # Internal: Модели используемые в отчете
        #
        # Returns Array of Arel::Table
        def models
          fail NotImplementedError
        end

        # Internal: Основной запрос отчета (Arel)
        #
        # Returns Arel::SelectManager
        def base_query
          fail NotImplementedError
        end

        # Internal: Поля запрашиваемые отчетом
        #
        # Returns String (SQL)
        def select
          fail NotImplementedError
        end

        # Internal: Порядок строк отчета
        #
        # Returns String (SQL)
        def order_by
          nil
        end

        # Internal: Фильтры отчета
        #
        # Returns Arel::SelectManager
        def filter(query)
          query
        end

        # Internal: Запрос количества строк в отчете
        #
        # Returns String (SQL)
        def count
          query.project(Arel.sql('COUNT(*) as count')).to_sql
        end

        # Internal: Запрос пачки строк отчета
        #
        #   offset - Numeric, число строк на которое сдвигается запрос
        #
        # Returns String (SQL)
        def take_batch(limit, offset)
          query.project(Arel.sql(select))
               .take(limit)
               .skip(offset)
               .order(order_by)
               .to_sql
        end
      end
    end
  end
end
