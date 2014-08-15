defmodule ScenarioBench.Callbacks do
  def start_link do
    Agent.start_link(fn -> %{scenarios: %{}} end, name: __MODULE__)
  end


  def add_scenario(name) do
    Agent.update __MODULE__, fn(state)->
      put_in state, [:scenarios, name], %{}
    end
  end


  def add(scenario, action, callback) do
    Agent.update __MODULE__, fn(state)->
      update_in state, [:scenarios, scenario, action], fn(callbacks)->
        (callbacks || []) ++ callback
      end
    end
  end


  def add(scenario, action, traversal, callback) do
    Agent.update __MODULE__, fn(state)->
      node_key = Enum.join(traversal, ".")

      update_in state, [:scenarios, scenario, action], fn(callbacks_for_nodes)->
        update_in (callbacks_for_nodes || %{}), [node_key], fn(callbacks_for_node)->
          (callbacks_for_node || []) ++ callback
        end
      end

    end
  end


  def get(scenario) do
    Agent.get __MODULE__, fn(state)->
      get_in state, [:scenarios, scenario]
    end
  end
end
