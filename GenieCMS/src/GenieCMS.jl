module GenieCMS

using Logging, LoggingExtras

function main()
  Base.eval(Main, :(const UserApp = GenieCMS))

  include(joinpath("..", "genie.jl"))

  Base.eval(Main, :(const Genie = GenieCMS.Genie))
  Base.eval(Main, :(using Genie))
end; main()

end
