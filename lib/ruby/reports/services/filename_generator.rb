require 'digest'
require 'json'

# coding: utf-8
module Ruby
  module Reports
    module Services
      # Module that generates file name
      # Usage:
      #   class SomeClass
      #     include Resque::Reports::Extensions::FilenameGen
      #
      #     # ...call somewhere...
      #     fname = generate_filename(%w(a b c), 'pdf')
      #     # 'fname' value is something like this:
      #     #   "a60428ee50f1795819b8486c817c27829186fa40.pdf"
      #   end
      class FilenameGenerator
        DEFAULT_EXTENSION = 'txt'

        def self.generate(args, fextension = nil)
          "#{hash(self.class.to_s, *args)}.#{fextension || DEFAULT_EXTENSION}"
        end

        private

        def self.hash(*args)
          Digest::SHA1.hexdigest(args.to_json)
        end
      end
    end
  end
end

