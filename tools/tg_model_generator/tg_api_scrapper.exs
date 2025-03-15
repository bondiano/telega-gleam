defmodule TgApiScrapper do
  @moduledoc """
  Scrapes the Telegram API documentation and generates a JSON file with the API methods and types.

  Based on https://github.com/rockneurotiko/telegram_api_json/
  """

  require Logger

  defstruct models: [], methods: [], generics: []

  defmodule Generic do
    defstruct [:name, :subtypes, :discriminator]
  end

  defmodule Model do
    defstruct [:name, :description, params: []]
  end

  defmodule Param do
    defstruct [:name, :type, :description, :one_of, optional: false]
  end

  @url "https://core.telegram.org/bots/api"

  @skip ["InputFile"]
  @generic_types [
    "InlineQueryResult",
    "InputMessageContent",
    "PassportElementError",
    "ChatMember",
    "BotCommandScope",
    "MenuButton",
    "InputMedia",
    "MaybeInaccessibleMessage",
    "ChatBoostSource",
    "MessageOrigin",
    "ReactionType",
    "PaidMedia",
    "InputPaidMedia",
    "RevenueWithdrawalState",
    "TransactionPartner",
    "BackgroundFill",
    "BackgroundType"
  ]
  @generic_discriminator_by_type %{
    "InlineQueryResult" => "type",
    "InputMessageContent" => "type",
    "PassportElementError" => "type",
    "ChatMember" => "status",
    "BotCommandScope" => "type",
    "MenuButton" => "type",
    "InputMedia" => "type",
    "MaybeInaccessibleMessage" => "type",
    "ChatBoostSource" => "type",
    "MessageOrigin" => "type",
    "ReactionType" => "type",
    "PaidMedia" => "type",
    "InputPaidMedia" => "type",
    "RevenueWithdrawalState" => "type",
    "TransactionPartner" => "type",
    "BackgroundFill" => "type",
    "BackgroundType" => "type"
  }

  @output_path Path.expand("./tg_api.generated.json", __DIR__)

  def run() do
    Mix.install([:floki, :httpoison, :poison])
    File.write!(@output_path, scrape() |> Poison.encode!(pretty: true))
  end

  defp scrape() do
    tree() |> analyze_html(%__MODULE__{})
  end

  defp tree do
    [{_, _, tree} | _] =
      get_html()
      |> Floki.parse_document!()
      |> Floki.find("#dev_page_content")

    tree
  end

  defp analyze_html([], result), do: result

  defp analyze_html([{"h4", _, _} = elem | rest], result) do
    name = Floki.text(elem)

    cond do
      name in @skip ->
        Logger.info("Skip: #{name}")
        analyze_html(rest, result)

      name in @generic_types ->
        Logger.info("Generic: #{name}")
        discriminator = @generic_discriminator_by_type[name]
        generic = extract_generic(name, discriminator, rest)
        result = %{result | generics: result.generics ++ [generic]}
        analyze_html(rest, result)

      empty_object?(rest) ->
        model = empty_object(name, rest)
        result = %{result | models: result.models ++ [model]}
        analyze_html(rest, result)

      upper?(name) ->
        case length(String.split(name)) do
          1 ->
            Logger.info("Model: #{name}")
            model = extract_model(name, rest)
            result = %{result | models: result.models ++ [model]}
            analyze_html(rest, result)

          _ ->
            analyze_html(rest, result)
        end

      true ->
        analyze_html(rest, result)
    end
  end

  defp analyze_html([_ | rest], result), do: analyze_html(rest, result)

  defp empty_object?([{"p", _, _} = elem | _rest]) do
    text = Floki.text(elem)

    String.contains?(text, "Currently holds no information")
  end

  defp empty_object?([{"table", _, _} | _rest]), do: false

  defp empty_object(name, tree) do
    Logger.debug("Building empty object: #{name}")
    description = tree |> find_next("p") |> Floki.text()
    %TgApiScrapper.Model{name: name, description: description, params: []}
  end

  defp extract_generic(name, discriminator, tree) do
    Logger.debug("Extracting generic: #{name}")
    subtypes = tree |> find_next("ul") |> Floki.find("li") |> Enum.map(&Floki.text/1)
    %TgApiScrapper.Generic{name: name, subtypes: subtypes, discriminator: discriminator}
  end

  defp extract_model(name, tree) do
    Logger.debug("Extracting model: #{name}")
    description = extract_model_description(tree) |> Floki.text()
    params = tree |> find_next("table") |> extract_table_params()

    %TgApiScrapper.Model{name: name, description: description, params: params}
  end

  defp extract_model_description([{"p", _, text} | _]), do: text
  defp extract_model_description(_), do: "No description available."

  defp extract_table_params(table) do
    table |> Floki.find("tr") |> Enum.drop(1) |> Enum.map(&table_row_to_param/1)
  end

  defp table_row_to_param(row) do
    {name_row, type_row, opt_row, extra_row} = extract_table_row(row)
    name = Floki.text(name_row)
    types = type_row |> Floki.text() |> parse_types()
    opt = Enum.count(opt_row) == 1
    description = extra_row |> Floki.text()

    one_of =
      if String.contains?(description, "one of") do
        Regex.scan(~r{“([^”]+)”}, description) |> Enum.map(&List.last/1)
      else
        nil
      end

    %TgApiScrapper.Param{
      name: name,
      type: types,
      optional: opt,
      description: description,
      one_of: one_of
    }
  end

  defp extract_table_row(row) do
    case row |> Floki.find("td") do
      [name, type, extra] -> {name, type, find_optional(extra), extra}
      [name, type, opt, extra | _] -> {name, type, keep_optional([opt]), extra}
    end
  end

  defp find_optional(extra) do
    extra |> Floki.find("em") |> keep_optional()
  end

  defp keep_optional(elements) do
    elements |> Enum.filter(fn e -> Floki.text(e) =~ "Optional" end)
  end

  defp parse_types(type_str) do
    type_str
    |> String.split(" or ")
    |> Stream.map(&String.trim/1)
    |> Enum.flat_map(&parse_types_elem/1)
  end

  defp parse_types_elem("Integer"), do: ["int"]
  defp parse_types_elem("String"), do: ["str"]
  defp parse_types_elem("Boolean"), do: ["bool"]
  defp parse_types_elem("True"), do: ["bool"]
  defp parse_types_elem("Float"), do: ["float"]
  defp parse_types_elem("Float number"), do: ["float"]
  defp parse_types_elem("InputFile"), do: ["file"]

  defp parse_types_elem("Array of " <> name) do
    more =
      case parse_types(name) do
        [] -> ["any"]
        other -> other
      end

    ["array", more]
  end

  defp parse_types_elem(name) do
    cond do
      String.contains?(name, " and ") ->
        [first | rest] = String.split(name, " and ")
        [left | _] = parse_types(first)
        [right | _] = rest |> Enum.join(" and ") |> parse_types()
        [left, right]

      upper?(name) ->
        [name]

      true ->
        []
    end
  end

  defp upper?(string) do
    f = String.first(string)
    f == String.upcase(f)
  end

  defp find_next(tree, find) do
    tree |> Floki.find(find) |> Enum.at(0)
  end

  defp get_html() do
    {:ok, resp} = HTTPoison.get(@url)
    resp.body
  end
end

TgApiScrapper.run()
