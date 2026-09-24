-- Installed as /etc/jjui/config.lua. jjui calls setup() once at start and
-- keeps this Lua VM alive, so `copied` survives between key presses.

local copied = {}
local repo_root = "."

local function fail(text)
  flash({ text = text, error = true })
end

local function current()
  local rev = jjui.revisions.current()
  if rev == nil then
    fail("no revision selected")
  end
  return rev
end

local function selection()
  local revs = jjui.revisions.checked()
  if #revs > 0 then
    return revs
  end
  local rev = current()
  if rev == nil then
    return nil
  end
  return { rev }
end

local function selected_file()
  local rev = jjui.context.change_id()
  local file = jjui.context.file()
  if rev == nil or file == nil then
    fail("no file selected")
    return nil
  end
  return rev, file
end

local function shell_quote(text)
  return "'" .. (text:gsub("'", "'\\''")) .. "'"
end

local function fileset(path)
  return 'root-file:"' .. (path:gsub('[\\"]', "\\%0")) .. '"'
end

local function show(rev, template)
  local out, err = jj("log", "--no-graph", "-r", rev, "-T", template)
  if err ~= nil then
    fail(err)
  end
  return out
end

local function copy(text, what)
  local _, err = copy_to_clipboard(text)
  if err ~= nil then
    fail(err)
  else
    flash("copied " .. what)
  end
end

local function index_of(list, value)
  for i, item in ipairs(list) do
    if item == value then
      return i
    end
  end
  return nil
end

local function toggle_copied()
  local revs = selection()
  if revs == nil then
    return
  end
  local all_copied = true
  for _, rev in ipairs(revs) do
    all_copied = all_copied and index_of(copied, rev) ~= nil
  end
  for _, rev in ipairs(revs) do
    local i = index_of(copied, rev)
    if all_copied then
      table.remove(copied, i)
    elseif i == nil then
      table.insert(copied, rev)
    end
  end
  flash(#copied .. " revision(s) copied")
end

local function paste()
  local rev = current()
  if rev == nil then
    return
  end
  if #copied == 0 then
    fail("nothing copied, press C first")
    return
  end
  local args = { "duplicate" }
  for _, id in ipairs(copied) do
    table.insert(args, id)
  end
  table.insert(args, "--insert-after")
  table.insert(args, rev)
  copied = {}
  jj_async(args)
end

local function move(flag, neighbour)
  return function()
    local rev = current()
    if rev ~= nil then
      jj_async("rebase", "-r", rev, flag, "exactly(" .. rev .. neighbour .. ", 1)")
    end
  end
end

local function fixup()
  local rev = current()
  if rev ~= nil then
    jj_async("squash", "-r", rev, "--use-destination-message")
  end
end

local function amend()
  local rev = current()
  if rev ~= nil then
    jj_async("squash", "--from", "@", "--into", rev, "--use-destination-message")
  end
end

local function author()
  local rev = current()
  if rev == nil then
    return
  end
  local reset, set, coauthor = "Reset author to me", "Set author", "Add co-author"
  local choice = choose({ title = "Amend commit attribute", options = { reset, set, coauthor }, ordered = true })
  if choice == reset then
    jj_async("metaedit", "--update-author", rev)
    return
  end
  if choice == nil then
    return
  end
  local who = input({ title = choice, prompt = "Name <email>: " })
  if who == nil or who == "" then
    return
  end
  if choice == set then
    jj_async("metaedit", "--author", who, rev)
    return
  end
  local description = show(rev, "description")
  if description ~= nil then
    local message = (description:gsub("%s+$", "")) .. "\n\nCo-authored-by: " .. who
    jj_async("metaedit", "-m", message, rev)
  end
end

local function tag()
  local rev = current()
  if rev == nil then
    return
  end
  local name = input({ title = "Tag name" })
  if name ~= nil and name ~= "" then
    jj_async("tag", "set", name, "-r", rev)
  end
end

local copy_templates = {
  { "change ID", "change_id" },
  { "commit ID", "commit_id" },
  { "subject", "description.first_line()" },
  { "message", "description" },
  { "author", 'author.name() ++ " <" ++ author.email() ++ ">"' },
  { "bookmarks", 'local_bookmarks.map(|b| b.name()).join(" ")' },
}

local function copy_attribute()
  local rev = current()
  if rev == nil then
    return
  end
  local labels = {}
  for _, entry in ipairs(copy_templates) do
    table.insert(labels, entry[1])
  end
  table.insert(labels, "diff")
  local choice = choose({ title = "Copy to clipboard", options = labels, ordered = true })
  if choice == "diff" then
    local out, err = jj("diff", "--git", "-r", rev)
    if err ~= nil then
      fail(err)
    else
      copy(out, "diff")
    end
    return
  end
  for _, entry in ipairs(copy_templates) do
    if entry[1] == choice then
      local out = show(rev, entry[2])
      if out ~= nil then
        copy(out, choice)
      end
    end
  end
end

local function copy_change_id()
  local rev = current()
  if rev == nil then
    return
  end
  local out = show(rev, "change_id.short()")
  if out ~= nil then
    copy(out, "change ID")
  end
end

local function difftool()
  local rev = current()
  if rev ~= nil then
    jj_interactive("diff", "--tool", "vscodium", "-r", rev)
  end
end

local function create_pr()
  local rev = current()
  if rev == nil then
    return
  end
  local out = show("heads(::" .. rev .. " & bookmarks())", 'local_bookmarks.map(|b| b.name()).join("\\n") ++ "\\n"')
  if out == nil then
    return
  end
  local names = split_lines(out)
  local name = names[1]
  if #names == 0 then
    fail("no bookmark at or below the selected revision")
    return
  elseif #names > 1 then
    name = choose({ title = "Open PR for bookmark", options = names })
  end
  if name ~= nil then
    exec_shell("gh pr create --fill --web --head " .. shell_quote(name))
  end
end

local function commit_ids(revset)
  local out = show(revset, 'commit_id ++ "\\n"')
  if out == nil then
    return nil
  end
  local ids = split_lines(out)
  if #ids == 0 then
    return "none()"
  end
  return table.concat(ids, " | ")
end

-- Port of the lazygit ctrl+n / ctrl+p commands: copy the selected revision
-- onto a fresh trunk and push it as a new bookmark to origin.
local function pr_branch(remote, trunk)
  return function()
    local rev = current()
    if rev == nil then
      return
    end
    local name = input({ title = "What is the new branch name?" })
    if name == nil or name == "" then
      return
    end
    local _, err = jj("git", "fetch", "--remote", remote)
    if err ~= nil then
      fail(err)
      return
    end
    local before = commit_ids("children(" .. trunk .. ")")
    if before == nil then
      return
    end
    _, err = jj("duplicate", rev, "--onto", trunk)
    if err ~= nil then
      fail(err)
      return
    end
    local dup = show("exactly(children(" .. trunk .. ") ~ (" .. before .. "), 1)", "change_id")
    if dup ~= nil then
      jj_async("git", "push", "--remote", "origin", "--named", name .. "=" .. dup)
    end
  end
end

local function checkout_file()
  local rev, file = selected_file()
  if rev ~= nil then
    jj_async("restore", "--from", rev, "--into", "@", fileset(file))
  end
end

local function edit_file()
  local _, file = selected_file()
  if file ~= nil then
    exec_shell('"${EDITOR:-vi}" ' .. shell_quote(file))
  end
end

local function open_file()
  local _, file = selected_file()
  if file == nil then
    return
  end
  local _, err = jj("util", "exec", "--", "sh", "-c", 'setsid -f xdg-open "$1" >/dev/null 2>&1', "_", file)
  if err ~= nil then
    fail(err)
  end
end

local function copy_file_attribute()
  local rev, file = selected_file()
  if rev == nil then
    return
  end
  local choice = choose({
    title = "Copy to clipboard",
    options = { "relative path", "absolute path", "file name", "diff of file" },
    ordered = true,
  })
  if choice == "relative path" then
    copy(file, choice)
  elseif choice == "absolute path" then
    copy(repo_root .. "/" .. file, choice)
  elseif choice == "file name" then
    copy((file:match("[^/]+$")), choice)
  elseif choice == "diff of file" then
    local out, err = jj("diff", "--git", "-r", rev, fileset(file))
    if err ~= nil then
      fail(err)
    else
      copy(out, choice)
    end
  end
end

local function copy_file_path()
  local _, file = selected_file()
  if file ~= nil then
    copy(file, "path")
  end
end

local function file_difftool()
  local rev, file = selected_file()
  if rev ~= nil then
    jj_interactive("diff", "--tool", "vscodium", "-r", rev, fileset(file))
  end
end

local function blame(at_revision)
  return function()
    local rev, file = selected_file()
    if rev == nil then
      return
    end
    if at_revision then
      jj_interactive("file", "annotate", "-r", rev, "--", file)
    else
      jj_interactive("file", "annotate", "--", file)
    end
  end
end

-- Conflicts live under the `x` prefix. `x m` tries mergiraf first and leaves
-- whatever it cannot settle recorded as a conflict for `x v` in VSCodium.
local function resolve_with(tool, interactive)
  return function()
    local rev = current()
    if rev == nil then
      return
    elseif interactive then
      jj_interactive("resolve", "-r", rev, "--tool", tool)
    else
      jj_async("resolve", "-r", rev, "--tool", tool)
    end
  end
end

local function list_conflicts()
  local rev = current()
  if rev == nil then
    return
  end
  local out, err = jj("resolve", "--list", "-r", rev)
  if err ~= nil then
    fail(err)
  else
    flash({ text = out, sticky = true })
  end
end

local function fetch()
  jj_async("git", "fetch")
end

local function push()
  jj_async("git", "push")
end

-- The revision list plays lazygit's commits panel, details its commit files
-- panel, the bookmark pane its branches panel, the oplog its reflog tab.
-- Each row is { scope, keys, action, desc }
-- plus a Lua function for custom actions or builtin args. A row replaces every
-- default binding of its action in that scope and takes its keys from other
-- defaults there, so help lists each key once. jjui builtins with no lazygit
-- counterpart keep their default key unless a lazygit key displaced them,
-- then they move to an alt or ctrl key.
local keymap = {
  { "ui", { "q", "ctrl+c" }, "ui.quit", "quit" },
  { "ui", "?", "ui.open_help", "keybindings" },
  { "ui", "f1", "ui.expand_status", "expand status help" },

  { "ui.preview", "shift+k", "ui.preview_scroll_up", "scroll diff up" },
  { "ui.preview", "shift+j", "ui.preview_scroll_down", "scroll diff down" },
  { "ui.preview", { "ctrl+u", "pgup" }, "ui.preview_half_page_up", "page diff up" },
  { "ui.preview", { "ctrl+d", "pgdown" }, "ui.preview_half_page_down", "page diff down" },
  { "ui.preview", "+", "ui.preview_expand", "bigger diff" },
  { "ui.preview", "_", "ui.preview_shrink", "smaller diff" },

  { "revisions", { "enter", "right", "l" }, "revisions.open_details", "view files" },
  { "revisions", "space", "revisions.new", "checkout (jj new)" },
  { "revisions", { "n", "shift+b" }, "revisions.open_set_bookmark", "new bookmark" },
  { "revisions", "r", "revisions.open_inline_describe", "reword" },
  { "revisions", "shift+r", "revisions.describe", "reword with editor" },
  { "revisions", "d", "revisions.open_abandon", "drop" },
  { "revisions", "s", "revisions.open_squash", "squash" },
  { "revisions", "f", "lazygit.fixup", "fixup into parent", fixup },
  { "revisions", "shift+a", "lazygit.amend", "amend with @", amend },
  { "revisions", "a", "lazygit.author", "amend commit attribute", author },
  { "revisions", "i", "revisions.open_rebase", "rebase" },
  { "revisions", "t", "revisions.open_revert", "revert" },
  { "revisions", "shift+t", "lazygit.tag", "tag", tag },
  { "revisions", "v", "revisions.toggle_select", "select" },
  { "revisions", "shift+c", "lazygit.copy", "copy (cherry-pick)", toggle_copied },
  { "revisions", "shift+v", "lazygit.paste", "paste (cherry-pick)", paste },
  { "revisions", { "ctrl+j", "alt+down" }, "lazygit.move_down", "move down one", move("--insert-before", "-") },
  { "revisions", { "ctrl+k", "alt+up" }, "lazygit.move_up", "move up one", move("--insert-after", "+") },
  { "revisions", "y", "lazygit.copy_attribute", "copy to clipboard", copy_attribute },
  { "revisions", "ctrl+o", "lazygit.copy_change_id", "copy change ID", copy_change_id },
  { "revisions", "z", "ui.open_undo", "undo" },
  { "revisions", "shift+z", "ui.open_redo", "redo" },
  { "revisions", "p", "lazygit.pull", "pull (git fetch)", fetch },
  { "revisions", "shift+p", "lazygit.push", "push", push },
  { "revisions", "0", "revisions.diff", "focus diff" },
  { "revisions", { "shift+w", "ctrl+e" }, "revisions.open_diff_range", "diffing options" },
  { "revisions", "ctrl+t", "lazygit.difftool", "external diff tool", difftool },
  { "revisions", "ctrl+s", "revset.edit", "filter (revset)", { clear = true } },
  { "revisions", "ctrl+f", "ui.file_search_toggle", "filter by file" },
  { "revisions", ":", "ui.exec_shell", "exec shell" },
  { "revisions", "$", "ui.exec_jj", "exec jj" },
  { "revisions", { "]", "[" }, "ui.open_oplog", "oplog (reflog tab)" },
  { "revisions", ",", "revisions.page_up", "previous page" },
  { "revisions", ".", "revisions.page_down", "next page" },
  { "revisions", { "<", "home" }, "revisions.go_to_top", "top" },
  { "revisions", { ">", "end" }, "revisions.go_to_bottom", "bottom" },
  { "revisions", "ctrl+g", "lazygit.create_pr", "create pull request", create_pr },
  { "revisions", "ctrl+n", "lazygit.pr_upstream", "PR off master@upstream", pr_branch("upstream", "master@upstream") },
  { "revisions", "ctrl+p", "lazygit.pr_origin", "PR off main@origin", pr_branch("origin", "main@origin") },
  { "revisions", "ctrl+a", "revisions.open_absorb", "absorb" },
  { "revisions", "shift+x", "revisions.split", "split" },
  { "revisions", "ctrl+l", "revisions.open_evolog", "evolog" },
  { "revisions", "alt+v", "revisions.open_duplicate", "duplicate to..." },
  { "revisions", "alt+c", "revisions.open_annotation", "annotate" },
  { "revisions", "alt+f", "revisions.ace_jump", "ace jump" },
  { "revisions", "alt+j", "revisions.jump_to_parent", "jump to parent" },
  { "revisions", "alt+k", "revisions.jump_to_children", "jump to children" },
  { "revisions", "alt+w", "ui.open_command_history", "command history" },

  { "revisions.quick_search", "n", "revisions.quick_search.next", "next match" },
  { "revisions.quick_search", "shift+n", "revisions.quick_search.prev", "prev match" },

  { "revisions.inline_describe", { "enter", "ctrl+s" }, "revisions.inline_describe.accept", "confirm" },
  { "revisions.inline_describe", { "shift+enter", "alt+enter" }, "revisions.inline_describe.new_line", "new line" },

  { "revisions.details", "enter", "revisions.details.diff", "view diff" },
  { "revisions.details", "d", "revisions.details.restore", "discard" },
  { "revisions.details", "c", "lazygit.checkout_file", "checkout file into @", checkout_file },
  { "revisions.details", "e", "lazygit.edit_file", "edit file", edit_file },
  { "revisions.details", "o", "lazygit.open_file", "open file", open_file },
  { "revisions.details", "y", "lazygit.copy_file_attribute", "copy to clipboard", copy_file_attribute },
  { "revisions.details", "ctrl+o", "lazygit.copy_file_path", "copy path", copy_file_path },
  { "revisions.details", "ctrl+t", "lazygit.file_difftool", "external diff tool", file_difftool },
  { "revisions.details", "b", "lazygit.blame", "blame at revision", blame(true) },
  { "revisions.details", "shift+b", "lazygit.blame_tree", "blame at @", blame(false) },
  { "revisions.details", "t", "revisions.details.revisions_changing_file", "file history" },

  { "oplog", "g", "oplog.restore", "reset to operation" },
  { "oplog", { "esc", "[", "]" }, "oplog.close", "back to revisions" },
  { "oplog.quick_search", "n", "oplog.quick_search.next", "next match" },
  { "oplog.quick_search", "shift+n", "oplog.quick_search.prev", "prev match" },

  { "bookmark_pane", "space", "bookmark_pane.new", "checkout (jj new)" },
  { "bookmark_pane", "n", "bookmark_pane.create", "new bookmark" },
  { "bookmark_pane", "shift+r", "bookmark_pane.rename", "rename" },
  { "bookmark_pane", "shift+d", "bookmark_pane.forget", "forget (local only)" },
  { "bookmark_pane", { "f", "p" }, "bookmark_pane.fetch", "fetch (pull)" },
  { "bookmark_pane", "enter", "bookmark_pane.set_revset", "view commits" },
  { "bookmark_pane", "=", "bookmark_pane.toggle_expand", "expand remotes" },
  { "bookmark_pane", "v", "bookmark_pane.toggle_select", "select" },
  { "bookmark_pane", { "esc", "b", "\\" }, "ui.preview_toggle", "back to diff" },
}

for _, scope in ipairs({ "revisions", "revisions.details", "revisions.evolog", "oplog" }) do
  table.insert(keymap, { scope, "\\", "ui.preview_toggle", "toggle diff" })
  table.insert(keymap, { scope, "|", "ui.preview_toggle_bottom", "diff right/bottom" })
end

local conflict_keys = {
  { "m", "conflicts.mergiraf", "resolve with mergiraf", resolve_with("mergiraf", false) },
  { "v", "conflicts.vscodium", "resolve in VSCodium", resolve_with("vscodium", true) },
  { "l", "conflicts.list", "list conflicted files", list_conflicts },
}

local function key_list(keys)
  if type(keys) == "string" then
    return { keys }
  end
  return keys
end

local function claims()
  local keys, actions = {}, {}
  for _, row in ipairs(keymap) do
    local scope = row[1]
    keys[scope] = keys[scope] or {}
    for _, key in ipairs(key_list(row[2])) do
      keys[scope][key] = true
    end
    actions[scope .. " " .. row[3]] = true
  end
  return keys, actions
end

local function without_claimed(bindings)
  local keys, actions = claims()
  local kept = {}
  for _, binding in ipairs(bindings) do
    local taken = keys[binding.scope] or {}
    local free = {}
    for _, key in ipairs(binding.key) do
      if not taken[key] then
        table.insert(free, key)
      end
    end
    local lost_all_keys = #binding.key > 0 and #free == 0
    if not actions[binding.scope .. " " .. binding.action] and not lost_all_keys then
      binding.key = free
      table.insert(kept, binding)
    end
  end
  return kept
end

function setup(config)
  repo_root = config.repo
  config.bindings = without_claimed(config.bindings)
  for _, row in ipairs(keymap) do
    local scope, keys, action, desc, extra = row[1], key_list(row[2]), row[3], row[4], row[5]
    if type(extra) == "function" then
      config.action(action, extra, { key = keys, scope = scope, desc = desc })
    else
      table.insert(config.bindings, { key = keys, scope = scope, action = action, desc = desc, args = extra })
    end
  end
  for _, row in ipairs(conflict_keys) do
    config.action(row[2], row[4], { seq = { "x", row[1] }, scope = "revisions", desc = row[3] })
  end
end
