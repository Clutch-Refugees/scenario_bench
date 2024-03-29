defmodule ScenarioBench.Runner do
  require Logger
  import ScenarioBench.Utils

  def run_by_name(scenario_name, data, run_options) do
    %{definition: scenario_definition, options: scenario_options} = ScenarioBench.get_scenario(scenario_name)
    options = Map.merge(scenario_options, run_options)
    options_with_stored_callbacks = add_stored_callbacks_to_options(scenario_name, options)
    run(scenario_definition, data, options_with_stored_callbacks)
  end


  def run(scenario, data, options) do
    unless run_global_callbacks(:before_all, options.callbacks) == :stop do
      run(scenario, data, scenario, options, [])
      run_global_callbacks(:after_all, options.callbacks)
    end
  end


  def run(_scenario, _data, [], _options, _traversal_path) do
  end


  def run(scenario, data, fields, options, traversal_path) when is_list(fields) do
    index = Enum.find_index fields, fn(field)->
      run(scenario, data, field, options, traversal_path) == :stop
    end

    case index do
      nil -> false
      _   -> :stop
    end
  end


  def run(scenario, data, field, options, traversal_path) do
    new_traversal_path = traversal_path ++ [field[:name]]
    extras = make_extras(new_traversal_path, data)
    node_key = get_node(new_traversal_path)

    unless run_callbacks_for_node(:before, node_key, options.callbacks, extras) == :stop do
      unless fill(scenario, field, data, options, new_traversal_path) == :stop do
        run_callbacks_for_node(:after, node_key, options.callbacks, extras)
      end
    end
  end


  defp fill(scenario, field, data, options, new_traversal_path) do
    if is_list(field[:type]) do
      fill_group(scenario, field, data, options, new_traversal_path)
    else
      fill_field(field, data, options, new_traversal_path)
    end
  end


  defp fill_group(scenario, field, data, options, traversal_path) do
    parent  = Enum.slice traversal_path, 0, length(traversal_path) - 1
    current_leaf = List.last(traversal_path)
    value = get_value_of(traversal_path, data)
    cond do
      value == nil -> true
      is_list(value) ->
        Enum.with_index(value)
        |> Enum.each(fn({_item, index})->
          new_traversal_path = parent ++ [{current_leaf, index}]
          run(scenario, data, field[:type], options, new_traversal_path)
        end)
      is_map(value) ->
        run(scenario, data, field[:type], options, parent ++ [current_leaf])
      true ->
        raise "Expected value for #{field[:name]} to be a list"
    end
  end


  defp fill_field(field, data, options, traversal_path) do
    value = get_value_of(traversal_path, data)
    unless value == nil do
      Logger.debug "FILL: #{field[:name]} of type #{field[:type]}"
      apply options[:filler], :fill, [traversal_path, field[:type], value]
    end
  end



  defp run_callbacks_for_node(action, node_key, callbacks, extras) do
    node_callbacks = get_in(callbacks, [action, node_key]) || []
    wildcard_callbacks = get_in( callbacks, [similar_callback_action(action)] ) || []
    run_callbacks action, node_key, (wildcard_callbacks ++ node_callbacks), extras
  end


  defp run_callbacks(_action, _node_key, [], _extras) do
  end


  defp run_callbacks(action, node_key, callbacks, extras) do
    index = Enum.find_index callbacks, fn(callback)->
      return_value = apply callback, [%{field: extras.field, data: extras.data, node: node_key}]
      return_value == :stop
    end

    case index do
      nil -> false
      _   -> :stop
    end
  end


  defp add_stored_callbacks_to_options(scenario_name, options) do
    stored_callbacks   = ScenarioBench.Callbacks.get(scenario_name)
    injected_callbacks = get_in(options, [:callbacks]) || %{}
    injected_prepend_callbacks = get_in(options, [:prepend_callbacks]) || %{}
    wildcard_callback_actions = [:before_all, :after_all, :before_each, :after_each]

    resolver = fn(callback_action_name, value1, value2)->
      if Enum.member?(wildcard_callback_actions, callback_action_name) do
        value1 ++ value2
      else
        Map.merge( value1, value2, fn(_key, v1, v2)-> v1 ++ v2 end)
      end
    end


    prepend_resolver = fn(callback_action_name, value1, value2)->
      if Enum.member?(wildcard_callback_actions, callback_action_name) do
        value2 ++ value1
      else
        Map.merge( value1, value2, fn(_key, v1, v2)-> v2 ++ v1 end)
      end
    end


    all_callbacks = Map.merge(stored_callbacks, injected_callbacks, resolver)
    |> Map.merge(injected_prepend_callbacks, prepend_resolver)

    Map.put(options, :callbacks, all_callbacks)
  end


  defp run_global_callbacks(action, all_callbacks) do
    ( get_in(all_callbacks, [action]) || [] )
    |> run_global_callback(nil)
  end


  defp run_global_callback(_callbacks, :stop), do: :stop
  defp run_global_callback([], _status) do
  end


  defp run_global_callback([callback | callbacks], _status) do
    run_global_callback callbacks, apply(callback, [])
  end
end
