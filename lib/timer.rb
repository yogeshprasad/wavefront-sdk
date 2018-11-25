module Rake
  # monkey-patch Rake
  #
  class Task
    alias _execute execute

    def execute(*args)
      t0 = Time.right_now
      res = _execute(*args)
      elapsed = t0 - Time.right_now
      @times = elapsed
      res
    end
  end
end

# embrace and extend
#
class Time
  def self.right_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
