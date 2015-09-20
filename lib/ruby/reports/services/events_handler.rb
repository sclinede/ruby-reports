module Ruby
  module Reports
    module Services
      class EventsHandler
        PROGRESS_STEP = 10

        pattr_initialize :progress_callback, :error_callback do
          @error_callback ||= ->(e) { fail e }
        end

        def progress(progress, total, force = false)
          if progress_callback && (force || progress % PROGRESS_STEP == 0)
            progress_callback.call progress, total
          end
        end

        def error
          error_callback ? error_callback.call($ERROR_INFO) : fail
        end
      end
    end
  end
end
