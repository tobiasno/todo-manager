defmodule TodoManager do
  @data_file ".todo-manager-entries"

  def main(args) do
    case args do
      [] ->
        list_entries()

      ["check", ref_code] ->
        check_entry(ref_code)

      ["new"] ->
        create_entry()

      ["delete", ref_code] ->
        delete_entry(ref_code)

      ["help"] ->
        display_help()

      _ ->
        IO.puts("Invalid command. Use 'todo help' for usage information.")
    end
  end

  defp list_entries do
    entries = read_entries()
    three_months_ago = :os.system_time(:second) - 3 * 30 * 24 * 60 * 60
  
    {_older_concluded_entries, entries} =
      Enum.split_with(entries, fn entry ->
        case String.split(entry, ":::") do
          [_, "[x]", timestamp | _] when is_binary(timestamp) ->
            case Integer.parse(timestamp) do
              {timestamp_int, _} -> timestamp_int < three_months_ago
              :error -> false
            end
          _ ->
            false
        end
      end)
  
    write_entries(entries)
  
    concluded_entries = filter_entries(entries, &match?([_, "[x]" | _], &1))
    todo_entries = filter_entries(entries, &match?([_, "[ ]", _, "TODO" | _], &1))
    waiting_entries = filter_entries(entries, &match?([_, "[ ]", _, "WAITING" | _], &1))
  
    display_entries("Concluded Entries", concluded_entries)
    display_entries("TODO Entries", todo_entries)
    display_entries("Waiting Entries", waiting_entries)
  end
  
  defp check_entry(ref_code) do
    entries = read_entries()
  
    case find_entry(entries, ref_code) do
      nil ->
        IO.puts("Entry with reference code #{ref_code} not found.")
  
      entry ->
        entry_parts = String.split(entry, ":::")
        updated_entry_parts = List.update_at(entry_parts, 1, fn _ -> "[x]" end)
        updated_entry = Enum.join(updated_entry_parts, ":::")
        updated_entries = replace_entry(entries, entry, updated_entry)
        write_entries(updated_entries)
        IO.puts("Entry #{ref_code} marked as completed.")
    end
  end
  
  defp create_entry do
    type = get_entry_type()
    entries = read_entries()
    ref_code = generate_ref_code(entries)
    timestamp = :os.system_time(:second)
    data = get_entry_data(type)
  
    entry =
      [ref_code, "[ ]", Integer.to_string(timestamp), type | data]
      |> Enum.join(":::")
  
    entries = entries ++ [entry]
    write_entries(entries)
    IO.puts("New entry created with reference code: #{ref_code}")
  end

  defp delete_entry(ref_code) do
    entries = read_entries()

    case find_entry(entries, ref_code) do
      nil ->
        IO.puts("Entry with reference code #{ref_code} not found.")

      entry ->
        updated_entries = List.delete(entries, entry)
        write_entries(updated_entries)
        IO.puts("Entry #{ref_code} deleted.")
    end
  end

  defp display_help do
    IO.puts("""
    Usage: todo [command]
  
    Commands:
      help     Display this help message
      new      Create a new todo or waiting entry
      check    Mark an entry as completed by providing the reference code
      delete   Delete an entry by providing the reference code
  
    When executed without any command, the program lists all entries in the terminal.
    """)
  end
  
  defp get_entry_type do
    IO.puts("Select entry type:")
    IO.puts("1. TODO")
    IO.puts("2. WAITING")

    case IO.gets("Enter your choice (1-2): ") |> String.trim() do
      "1" -> "TODO"
      "2" -> "WAITING"
      _ -> IO.puts("Invalid choice. Please try again.") && get_entry_type()
    end
  end
  
  defp get_entry_data("TODO") do
    comment = get_input("Enter a comment describing the task: ")
    entity = get_input("Enter the name of the entity related to the task (@ will be added): ")
    entity = "@" <> entity
    date = get_date("Enter a date (YYYY-MM-DD): ")
    [comment, entity, date]
  end
  
  defp get_entry_data("WAITING") do
    waiting_for = get_input("Enter what you are waiting for (e.g., money, email): ")
    who = get_input("Enter who you are waiting for: ")
    comment = get_input("Enter a comment about what it is about: ")
    deadline = get_date("Enter a deadline (YYYY-MM-DD): ")
    [waiting_for, who, comment, deadline]
  end

  defp get_input(prompt) do
    case IO.gets(prompt) |> String.trim() do
      "" -> IO.puts("Input cannot be empty. Please try again.") && get_input(prompt)
      input -> input
    end
  end

  defp get_date(prompt) do
    one_week_from_now = Date.utc_today() |> Date.add(7) |> Date.to_string()
    prompt = prompt <> " (default: #{one_week_from_now}): "
  
    case IO.gets(prompt) |> String.trim() do
      "" -> one_week_from_now
      date ->
        case Date.from_iso8601(date) do
          {:ok, _} -> date
          {:error, _} -> IO.puts("Invalid date format. Please try again.") && get_date(prompt)
        end
    end
  end
  
  defp generate_ref_code(entries) do
    characters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    code_length = 6
  
    ref_code =
      characters
      |> String.graphemes()
      |> Enum.shuffle()
      |> Enum.take(code_length)
      |> Enum.join()
  
    if ref_code_exists?(entries, ref_code) do
      generate_ref_code(entries)
    else
      ref_code
    end
  end
  
  defp ref_code_exists?(entries, ref_code) do
    Enum.any?(entries, fn entry ->
      String.starts_with?(entry, ref_code)
    end)
  end
  
  defp read_entries do
    case File.read(@data_file) do
      {:ok, content} -> String.split(content, "\n", trim: true)
      {:error, _} -> []
    end
  end
  
  defp write_entries(entries) do
    File.write!(@data_file, Enum.join(entries, "\n"))
  end

  defp filter_entries(entries, condition) do
    entries
    |> Enum.filter(fn entry ->
      entry
      |> String.split(":::")
      |> condition.()
    end)
    |> Enum.sort_by(fn entry -> Enum.at(String.split(entry, ":::"), 2) |> String.to_integer() end)
  end

  defp find_entry(entries, ref_code) do
    Enum.find(entries, fn entry -> String.starts_with?(entry, ref_code) end)
  end

  defp replace_entry(entries, old_entry, new_entry) do
    Enum.map(entries, fn entry ->
      if entry == old_entry, do: new_entry, else: entry
    end)
  end

  defp display_entries(title, entries) do
    IO.puts("\n#{title}:")

    entries
    |> Enum.map(fn entry ->
      entry
      |> String.split(":::")
      |> Enum.map_join("   ", fn
        "[ ]" -> "[ ]"
        "[x]" -> "[x]"
        field -> field
      end)
    end)
    |> Enum.each(&IO.puts/1)
  end
end

TodoManager.main(System.argv())
