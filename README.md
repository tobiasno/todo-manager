# todo-manager
A small todo and suspense file manager for the terminal written in elixir

~~~
Usage: todo [command]

Commands:
  help     Display this help message
  new      Create a new todo or waiting entry
  check    Mark an entry as completed by providing the reference code
  delete   Delete an entry by providing the reference code

When executed without any command, the program lists all entries in the terminal.
~~~

Elixir is my new pet language and I was looking for a small project to learn.

The manager knows waiting for entries additional to todo entries, so you are not forgotten by people who promised to come back to you. All data is saved in a human readable and easy to edit text file.
