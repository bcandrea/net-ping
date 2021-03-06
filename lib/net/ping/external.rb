require 'open3'
require 'rbconfig'

require File.join(File.dirname(__FILE__), 'ping')

# The Net module serves as a namespace only.
module Net

  # The Ping::External class encapsulates methods for external (system) pings.
  class Ping::External < Ping
    # Pings the host using your system's ping utility and checks for any
    # errors or warnings. Returns true if successful, or false if not.
    #
    # If the ping failed then the Ping::External#exception method should
    # contain a string indicating what went wrong. If the ping succeeded then
    # the Ping::External#warning method may or may not contain a value.
    #
    def ping(host = @host)
      super(host)

      pcmd = ['ping']
      bool = false

      case RbConfig::CONFIG['host_os']
        when /linux|bsd|osx|mach|darwin/i
          pcmd += ['-c1', host]
        when /solaris|sunos/i
          pcmd += [host, '1']
        when /hpux/i
          pcmd += [host, '-n1']
        when /win32|windows|msdos|mswin|cygwin|mingw/i
          pcmd += ['-n', '1', host]
        else
          pcmd += [host]
      end

      start_time = Time.now

      begin
        err = nil

        Timeout.timeout(@timeout){
          Open3.popen3(*pcmd) do |stdin, stdout, stderr, thread|
            err = stderr.gets # Can't chomp yet, might be nil

            case thread.value.exitstatus
              when 0
                bool = true  # Success, at least one response.
                if err & err =~ /warning/i
                  @warning = err.chomp
                end
              when 2
                bool = false # Transmission successful, no response.
                @exception = err.chomp
              else
                bool = false # An error occurred
                @exception = err.chomp
            end
          end
        }
      rescue Exception => error
        @exception = error.message
      end

      # There is no duration if the ping failed
      @duration = Time.now - start_time if bool

      bool
    end

    alias ping? ping
    alias pingecho ping
  end
end
