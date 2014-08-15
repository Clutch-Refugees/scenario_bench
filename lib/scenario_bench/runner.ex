defmodule ScenarioBench.Runner do
  import ScenarioBench.Utils

  def run_by_name(scenario_name, data, run_options) do
    {scenario_definition, scenario_options} = ScenarioBench.get_scenario(scenario_name)
    options = Map.merge(scenario_options, run_options)
    options_with_stored_callbacks = add_stored_callbacks(scenario_name, options)
    ScenarioBench.Runner.run(scenario_definition, data, options_with_stored_callbacks)
  end


  def run(scenario, data, options) do
    case run_global_callbacks(:before_all, options.callbacks) do
      :stop -> true
      _ -> run(scenario, data, scenario, options, [])
    end

    run_global_callbacks(:after_all, options.callbacks)
  end


  def run(_scenario, _data, [], _options, _tree) do
  end


  def run(scenario, data, [field | fields], options, traversal_path) do
    traversal_path = traversal_path ++ [field[:name]]
    extras = make_extras(traversal_path, data)

    case run_callbacks_for_node(:before, node, options.callbacks, extras) do
      :stop -> true
      _ ->
        case is_list(field[:type]) do
          true ->
            fill_group scenario, data, options, traversal_path
          false ->
            fill_field field, data, options, traversal_path
        end
    end


    case run_callbacks_for_node(:after, node, options.callbacks, extras) do
      :stop -> true
      _ ->
        run(scenario, data, fields, options, traversal_path)
    end
  end


  defp fill_group(scenario, data, options, traversal_path) do
    field = get_in scenario, traversal_path
    parent  = Enum.slice traversal_path, 0, length(traversal_path) - 1
    current_leaf = List.last(traversal_path)
    case get_value_of(traversal_path, data) do
      nil -> true
      values when is_list(values) ->
        Enum.with_index(values)
        |> Enum.each(fn({_item, index})->
             new_traversal_path = parent ++ {current_leaf, index}
             run(scenario, data, field[:type], options, new_traversal_path)
           end)
      _anything ->
        raise "Expected value for #{field[:name]} to be a list"
    end
  end


  defp fill_field(field, data, _options, traversal_path) do
    case get_value_of(traversal_path, data) do
      nil   -> true
        IO.inspect "SKIP: #{field[:name]}"
      value ->
        IO.inspect "FILL: #{field[:name]} with #{value}"
    end
  end



  defp run_callbacks_for_node(action, node, callbacks, extras) do
    node_callbacks = get_in(callbacks, [action, node]) || []
    wildcard_callbacks = get_in( callbacks, [similar_callback_action(action)] ) || []
    run_callbacks action, node, (wildcard_callbacks ++ node_callbacks), extras
  end


  defp run_callbacks(_action, _node, [], _extras) do
  end


  defp run_callbacks(action, node, [callback | callbacks], extras) do
    return_value = apply callback, [%{field: extras.field, data: extras.data, node: node}]
    case return_value do
      :stop -> :stop
      _ ->
        run_callbacks action, node, callbacks, extras
    end
  end


  defp add_stored_callbacks(scenario_name, options) do
    stored_callbacks   = ScenarioBench.Callbacks.get(scenario_name)
    injected_callbacks = get_in(options, [:callbacks]) || %{}
    wildcard_callback_actions = [:before_all, :after_all, :before_each, :after_each]

    resolver = fn(callback_action_name, value1, value2)->
      case Enum.member?(wildcard_callback_actions, callback_action_name) do
        true  -> value1 ++ value2
        false -> Map.merge( value1, value2, fn(_key, v1, v2)-> v1 ++ v2 end)
      end
    end

    all_callbacks = Map.merge stored_callbacks, injected_callbacks, resolver
    Map.put(options, :callbacks, all_callbacks)
  end



  defp run_global_callbacks(action, all_callbacks) when is_atom(action) do
    get_in all_callbacks, [action]
    |> run_global_callbacks(nil)
  end

  defp run_global_callbacks(_callbacks, :stop), do: :stop

  defp run_global_callbacks([callback | callbacks], _status) do
    run_global_callbacks callbacks, apply(callback, [])
  end
end
