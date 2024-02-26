local highlights = require("highlights")

local M = {}

-- Dummy for now
local settings = {
  async_loading = true,
}

local apply_highlights = function(highlights)
  for name, values in pairs(highlights) do
    vim.api.set_nvim_hl(0, name, values)
  end
end

local async

---loads highlights asynchronously
local load_async = function()
    for _, fn in pairs(highlights.async_highlights) do
        -- fn() returns a table of highlights to be applied
        apply_highlights(fn())
    end

    -- load terminal colors
    -- if not settings.disable.term_colors then
    --     highlights.load_terminal();
    -- end

    -- load user defined higlights
    -- if type(settings.custom_highlights) == "table" then
    --     apply_highlights(settings.custom_highlights)
    -- end

    -- if this function gets called asyncronously, this closure is needed
    if (async) then
        async:close()
    end
end

M.load = function()
    -- schedule the async function if async is enabled
    if settings.async_loading then
        async = vim.loop.new_async(vim.schedule_wrap(load_async))
    end

    -- apply highlights one by one
    for _, fn in pairs(highlights.main_highlights) do
        -- fn() returns a table of highlights to be applied
        apply_highlights(fn())
    end

	-- if async is enabled, send the function
    if settings.async_loading then
        async:send()
    else
        load_async()
    end
end

M.load()

return M
