require 'tempfile'
# coding: utf-8
module Ruby
  module Reports
    # Class describes how to storage and access cache file
    # NOTE: Every time any cache file is opening,
    #       cache is cleared from old files.
    class CacheFile
      DEFAULT_EXPIRE_TIME = 86_400
      DEFAULT_CODING = 'utf-8'.freeze

      attr_reader :dir, :ext, :coding, :expiration_time
      def initialize(dir, filename, options = {})
        @dir = dir
        @filename = File.join(dir, filename)
        @ext = File.extname(@filename)

        # options
        @coding = options[:coding] || DEFAULT_CODING
        @expiration_time = options[:expire_in] || DEFAULT_EXPIRE_TIME
      end

      def exists?
        !expired?(@filename)
      end
      alias_method :ready?, :exists?

      def filename
        fail 'File doesn\'t exist, check exists? before' unless exists?
        @filename
      end

      def open(force = false)
        prepare_cache_dir

        (force ? clear : return) if File.exists?(@filename)

        with_tempfile do |tempfile|
          yield tempfile

          tempfile.close
          FileUtils.cp(tempfile.path, @filename)
          FileUtils.chmod(0644, @filename)
        end
      end

      def clear
        FileUtils.rm_f(@filename)
      end

      protected

      def with_tempfile
        yield(tempfile = Tempfile.new(Digest::MD5.hexdigest(@filename), :encoding => coding))
      ensure
        return unless tempfile
        tempfile.close unless tempfile.closed?
        tempfile.unlink
      end

      def prepare_cache_dir
        FileUtils.mkdir_p dir # create folder if not exists
        clear_expired_files
      end

      def clear_expired_files
        # TODO: avoid races when worker building
        #       his report longer than @expiration_time
        FileUtils.rm_f cache_files_array.select { |fname| expired?(fname) }
      end

      def expired?(fname)
        return true unless File.file?(fname)
        File.mtime(fname) + expiration_time < Time.now
      end

      def cache_files_array
        Dir.new(dir)
           .map { |fname| File.join(dir, fname) if File.extname(fname) == ext }
           .compact
      end
    end
  end
end
