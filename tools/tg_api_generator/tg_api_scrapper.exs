defmodule TgApiScrapper do
  @moduledoc """
  Scrapes the Telegram API documentation and generates a JSON file with the API methods and types.

  Based on https://github.com/rockneurotiko/telegram_api_json/
  """

  require Logger

  defstruct models: [], methods: [], generics: []

  defmodule Generic do
    defstruct [:name, :subtypes]
  end

  defmodule Model do
    defstruct [:name, :description, params: []]
  end

  defmodule Method do
    defstruct [:name, :type, :return, :description, params: []]
  end

  defmodule Param do
    defstruct [:name, :type, :description, optional: false]
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

  @zero_parameters ["getMe", "getWebhookInfo", "logOut", "close"]

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
        generic = extract_generic(name, rest)
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
        Logger.info("Method: #{name}")
        method = extract_method(name, rest)
        result = %{result | methods: result.methods ++ [method]}
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

  defp extract_generic(name, tree) do
    Logger.debug("Extracting generic: #{name}")

    subtypes = tree |> find_next("ul") |> Floki.find("li") |> Enum.map(&Floki.text/1)

    %TgApiScrapper.Generic{name: name, subtypes: subtypes}
  end

  defp extract_model(name, tree) do
    Logger.debug("Extracting model: #{name}")
    description = extract_model_description(tree) |> Floki.text()
    params = tree |> find_next("table") |> extract_table_params()

    %TgApiScrapper.Model{name: name, description: description, params: params}
  end

  defp extract_model_description([{"p", _, text} | _]), do: text
  defp extract_model_description(_), do: "No description available."

  defp extract_method(name, tree) do
    type = if String.starts_with?(name, "get"), do: "get", else: "post"
    description = tree |> find_next("p") |> Floki.text()
    returned = description |> extract_return_type()

    params =
      case name in @zero_parameters do
        true -> []
        false -> tree |> find_next("table") |> extract_table_params()
      end

    %TgApiScrapper.Method{
      name: name,
      type: type,
      return: returned,
      description: description,
      params: params
    }
  end

  defp extract_table_params(table) do
    table |> Floki.find("tr") |> Enum.drop(1) |> Enum.map(&table_row_to_param/1)
  end

  defp table_row_to_param(row) do
    {name_row, type_row, opt_row, extra_row} = extract_table_row(row)
    name = Floki.text(name_row)
    types = type_row |> Floki.text() |> parse_types()
    opt = Enum.count(opt_row) == 1
    description = extra_row |> Floki.text()

    %TgApiScrapper.Param{name: name, type: types, optional: opt, description: description}
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

  @simple_return_r ~r{(?:r|R)eturns (?:the |a )?([^\s]+)}
  @as_object_r ~r{(?:r|R)eturns the (?:.+ )?(?:as |a |as a )([^\s]+)}
  @is_returned_r ~r{([^\s]+) (?:object )?is returned}

  @all_type_regexes_r [@as_object_r, @simple_return_r, @is_returned_r]

  defp extract_return_type(type) do
    post_ts = [
      "Returns information about the created topic as a ",
      "Returns basic information about the bot in form of a ",
      "Returns the uploaded "
    ]

    cond do
      String.contains?(type, "Returns an Array of Update") ->
        [["array", "Update"]]

      String.contains?(type, "On success, an array of Messages") ->
        [["array", "Message"]]

      String.contains?(type, "File object is returned") ->
        ["File"]

      String.contains?(type, "Returns an Array of GameHighScore") ->
        [["array", "GameHighScore"]]

      String.contains?(type, "Returns an Array of ChatMember") ->
        [["array", "ChatMember"]]

      String.contains?(type, "Returns an Array of BotCommand") ->
        [["array", "BotCommand"]]

      String.contains?(type, "Returns an Array of Sticker") ->
        [["array", "Sticker"]]

      String.contains?(
        type,
        "On success, if the message is not an inline message"
      ) ->
        # Special case for setGameScore and stopMessageLiveLocation https://core.telegram.org/bots/api#setgamescore
        ["Message", "true"]

      Enum.any?(post_ts, &String.contains?(type, &1)) ->
        t = Enum.find(post_ts, &String.contains?(type, &1))

        typ = type |> String.split(t) |> Enum.at(1) |> String.split() |> Enum.at(0) |> good_type()

        [typ]

      true ->
        Enum.reduce_while(@all_type_regexes_r, ["any"], fn r, acc ->
          case Regex.run(r, type) do
            nil ->
              {:cont, acc}

            match ->
              {:halt, match |> Enum.take(-1) |> Enum.map(&good_type/1)}
          end
        end)
    end
  end

  defp good_type(type) when is_binary(type) do
    type = type |> String.trim(".") |> String.trim(",") |> String.trim()

    case type do
      "Int" -> "int"
      "String" -> "str"
      "True" -> "true"
      other -> other
    end
  end

  defp good_type(type), do: type

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
