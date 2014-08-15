defmodule ScenarioBench.Runner do

  def run_by_name(scenario_name, data, run_options) do
    {scenario_definition, scenario_options} = ScenarioBench.get_scenario(scenario_name)
    options = Map.merge(scenario_options, run_options)
    options_with_stored_callbacks = add_stored_callbacks(scenario_name, options)
    ScenarioBench.Runner.run(scenario_definition, data, options_with_stored_callbacks)
  end


  def run(scenario, data, options) do
    run(scenario, data, scenario, options, [])
  end


  def run(_scenario, _data, [], _options, _tree) do
  end


  def run(scenario, data, [field | fields], options, tree) do
    node_path = tree ++ [field[:name]]
    case is_list(field[:type]) do
      true ->
        fill_group node_path, data, options, node_path
      false ->
        fill_field field, data, options, node_path
    end

    run(scenario, data, fields, options, tree)
  end


  defp fill_group(scenario, data, options, node_path) do
    field = get_in scenario, node_path
    parent_node  = Enum.slice node_path, 0, length(node_path) - 1
    current_leaf = List.last(node_path)
    case get_value_of(node_path, data) do
      nil -> true
      values when is_list(values) ->
        Enum.with_index(values)
        |> Enum.each(fn({_item, index})->
             new_node_path = parent_node ++ {current_leaf, index}
             run(scenario, data, field[:type], options, new_node_path)
           end)
      _anything ->
        raise "Expected value for #{field[:name]} to be a list"
    end
  end


  defp fill_field(field, data, _options, node_path) do
    field_info = %{ node: node_path }
    case get_value_of(node_path, data) do
      nil   -> true
        IO.inspect "SKIP: #{field[:name]}"
      value ->
        IO.inspect "FILL: #{field[:name]} with #{value}"
    end
  end


  def get_value_of([], data), do: data
  def get_value_of(fields, nil), do: nil


  def get_value_of([path_item | path_items], data) when is_tuple(path_item) do
    {leaf_name, index} = path_item
    case get_in(data, [leaf_name]) do
      nil ->
        node_data_of_index = nil
      node_data ->
        node_data_of_index = Enum.fetch!(node_data, index)
    end
    get_value_of(path_items, node_data_of_index)
  end


  def get_value_of([path_item | path_items], data) do
    node_data = get_in(data, [path_item])
    get_value_of(path_items, node_data)
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
end
