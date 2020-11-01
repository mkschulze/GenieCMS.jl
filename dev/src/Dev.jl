module Dev

using Logging, LoggingExtras

function main()
  Base.eval(Main, :(const UserApp = Dev))

  include(joinpath("..", "genie.jl"))

  Base.eval(Main, :(const Genie = Dev.Genie))
  Base.eval(Main, :(using Genie))
end; main()

end
