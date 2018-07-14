module Scylla
  module Util
    record ShResult, stdout = [] of String, stderr = [] of String, status = Process::Status.new

    def sh(*cmd)
      executable = ""
      args = [] of String

      cmd.each_with_index do |a, i|
        if i == 0
          executable = a
        else
          args << a
        end
      end

      stdout = [] of String
      stderr = [] of String

      pp({executable => args})

      Process.run(executable, args: args) do |status|
        status.output.each_line do |line|
          stdout << line
          L.debug line
        end
        status.error.each_line.each do |line|
          stderr << line
          L.debug line
        end
      end

      ShResult.new(stdout, stderr, $?)
    end

    def sh(*cmd, &block : String, String -> _)
      executable = ""
      args = [] of String

      cmd.each_with_index do |a, i|
        if i == 0
          executable = a
        else
          args << a
        end
      end

      sh(executable, args, &block)
    end

    def sh(cmd : String, args : Array(String), &block : String, String -> _)
      dbg = cmd
      args.each do |arg|
        if arg =~ /^[\w\/.:-]+$/
          dbg += " #{arg}"
        else
          dbg += " '#{arg}'"
        end
      end

      L.debug dbg
      block.call("command", dbg)

      Process.run(cmd, args: args) do |status|
        status.output.each_line do |line|
          L.debug "stdout: #{line}"
          block.call("stdout", line)
        end

        status.error.each_line do |line|
          L.debug "error: #{line}"
          block.call("error", line)
        end
      end

      raise "#{cmd} #{args} failed" unless $?.success?
      $?
    end
  end
end
