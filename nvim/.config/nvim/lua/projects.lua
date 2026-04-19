local M = {}

local data_path = vim.fn.stdpath("data") .. "/projects.json"

local function read_projects()
    local f = io.open(data_path, "r")
    if not f then
        return {}
    end
    local content = f:read("*a")
    f:close()
    if content == "" then
        return {}
    end
    local ok, decoded = pcall(vim.json.decode, content)
    if not ok or type(decoded) ~= "table" then
        return {}
    end
    return decoded
end

local function write_projects(projects)
    local f = io.open(data_path, "w")
    if not f then
        vim.notify("projects: cannot write " .. data_path, vim.log.levels.ERROR)
        return
    end
    f:write(vim.json.encode(projects))
    f:close()
end

local function expand(path)
    return vim.fn.fnamemodify(vim.fn.expand(path), ":p"):gsub("/$", "")
end

function M.list()
    return read_projects()
end

function M.add(path)
    path = path and path ~= "" and expand(path) or expand(vim.fn.getcwd())
    if vim.fn.isdirectory(path) ~= 1 then
        vim.notify("projects: not a directory: " .. path, vim.log.levels.ERROR)
        return
    end
    local projects = read_projects()
    for _, p in ipairs(projects) do
        if p == path then
            vim.notify("projects: already added: " .. path, vim.log.levels.INFO)
            return
        end
    end
    table.insert(projects, path)
    write_projects(projects)
    vim.notify("projects: added " .. path, vim.log.levels.INFO)
end

function M.remove(path)
    local projects = read_projects()
    if not path or path == "" then
        vim.ui.select(projects, { prompt = "Remove project:" }, function(choice)
            if choice then
                M.remove(choice)
            end
        end)
        return
    end
    path = expand(path)
    local kept = {}
    for _, p in ipairs(projects) do
        if p ~= path then
            table.insert(kept, p)
        end
    end
    write_projects(kept)
    vim.notify("projects: removed " .. path, vim.log.levels.INFO)
end

function M.switch(path)
    if vim.fn.isdirectory(path) ~= 1 then
        vim.notify("projects: missing directory: " .. path, vim.log.levels.ERROR)
        return
    end
    vim.cmd("silent! %bd!")
    vim.cmd("cd " .. vim.fn.fnameescape(path))
    vim.notify("projects: switched to " .. path, vim.log.levels.INFO)
    vim.schedule(function()
        vim.cmd("Telescope find_files")
    end)
end

function M.pick()
    local projects = read_projects()
    if #projects == 0 then
        vim.notify("projects: none saved yet. Use :ProjectAdd [path]", vim.log.levels.INFO)
        return
    end

    local ok, pickers = pcall(require, "telescope.pickers")
    if not ok then
        vim.ui.select(projects, {
            prompt = "Switch project:",
            format_item = function(p)
                return vim.fn.fnamemodify(p, ":t") .. "  " .. p
            end,
        }, function(choice)
            if choice then
                M.switch(choice)
            end
        end)
        return
    end

    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers
        .new({}, {
            prompt_title = "Projects",
            finder = finders.new_table({
                results = projects,
                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = vim.fn.fnamemodify(entry, ":t"),
                        ordinal = vim.fn.fnamemodify(entry, ":t"),
                        path = entry,
                    }
                end,
            }),
            sorter = conf.generic_sorter({}),
            previewer = conf.file_previewer({}),
            attach_mappings = function(bufnr)
                actions.select_default:replace(function()
                    local selection = action_state.get_selected_entry()
                    actions.close(bufnr)
                    if selection then
                        M.switch(selection.value)
                    end
                end)
                return true
            end,
        })
        :find()
end

function M.setup()
    vim.api.nvim_create_user_command("ProjectAdd", function(opts)
        M.add(opts.args)
    end, { nargs = "?", complete = "dir", desc = "Add a project directory" })

    vim.api.nvim_create_user_command("ProjectRemove", function(opts)
        M.remove(opts.args)
    end, { nargs = "?", desc = "Remove a project directory" })

    vim.api.nvim_create_user_command("ProjectList", function()
        local projects = read_projects()
        if #projects == 0 then
            print("No projects saved.")
            return
        end
        for i, p in ipairs(projects) do
            print(string.format("%d. %s", i, p))
        end
    end, { desc = "List saved projects" })
end

return M


