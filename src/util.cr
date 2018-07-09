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

    pp({executable => args})

    Process.run(executable, args: args) do |status|
      spawn do
        begin
          status.output.each_line do |line|
            L.debug line
            block.call("stdout", line)
          end
        rescue ex
          pp ex
        end
      end

      spawn do
        begin
          status.error.each_line.each do |line|
            L.debug line
            block.call("stderr", line)
          end
        rescue ex
          pp ex
        end
      end
    end

    raise "#{executable} failed" unless $?.success?
    $?
  end
end
