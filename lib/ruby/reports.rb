require 'forwardable'
require 'attr_extras'

require 'ruby/reports/services'

require 'ruby/reports/cache_file'
require 'ruby/reports/base_report'
require 'ruby/reports/csv_report'
require 'ruby/reports/cache_file'
require 'ruby/reports/config'

require 'ruby/reports/version'

module Ruby
  module Reports
    CP1251 = 'cp1251'.freeze
    UTF8 = 'utf-8'.freeze
  end
end
