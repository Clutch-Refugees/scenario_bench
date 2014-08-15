defmodule ScenarioBench.Scenarios do

  def start_link do
    Agent.start_link(fn -> %{scenarios: %{}} end, name: __MODULE__)
  end


  def add(name, scenario_definition, options \\ %{}) do
    Agent.update(__MODULE__, fn(state)->
      ScenarioBench.Callbacks.add_scenario(name)
      put_in state, [:scenarios, name], %{definition: scenario_definition, options: options}
    end)
  end


  def get(name) do
    Agent.get __MODULE__, fn(state)->
      get_in state, [:scenarios, name]
    end
  end
end
