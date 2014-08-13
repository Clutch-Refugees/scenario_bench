defmodule ScenarioBench.Scenarios do

  def start_link do
    Agent.start_link(fn -> %{scenarios: %{}} end, name: __MODULE__)
  end


  def add(name, scenario_definition, options \\ %{}) do
    Agent.update(__MODULE__, fn(state)->
      put_in state, [:scenarios, name], %{definition: scenario_definition, options: options}
      ScenarioBench.Callbacks.add_scenario(name)
    end)
  end
end
