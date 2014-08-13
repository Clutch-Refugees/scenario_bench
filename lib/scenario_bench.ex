defmodule ScenarioBench do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(ScenarioBench.Scenarios, []),
      worker(ScenarioBench.Callbacks, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ScenarioBench.Supervisor]
    Supervisor.start_link(children, opts)
  end


  defdelegate add_scenario(name, scenario_definition, options),    to: ScenarioBench.Scenarios, as: :add
  defdelegate add_callback(scenario, action, callback),            to: ScenarioBench.Callbacks, as: :add
  defdelegate add_callback(scenario, action, traversal, callback), to: ScenarioBench.Callbacks, as: :add

end
