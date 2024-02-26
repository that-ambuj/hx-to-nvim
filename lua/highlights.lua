local decodeFromFile = package.loadlib("./toml.so", "decodeFromFile")
local success, t = pcall(decodeFromFile, "gruvbox.toml")

local p = t.palette

local function exists(list, elem)
  for _, val in ipairs(list) do
    if val == elem then
      return true
    end
  end
  return false
end

local function attr_to_setting(attr)
  if type(attr) == "string" then
    return { fg = p[attr] }
  end

  if type(attr) == "table" then
    local setting = {}

    if attr.fg ~= nil then
      setting.fg = p[attr.fg]
    end

    if attr.bg ~= nil then
      setting.bg = p[attr.bg]
    end

    if attr.modifiers ~= nil then
      if exists(attr.modifiers, "bold") then
        setting.bold = true
      end

      -- TODO: support new syntax for underline
      if exists(attr.modifiers, "underlined") then
        setting.undercurl = true
        setting.sp = t.fg or t.bg
      end

      if exists(attr.modifiers, "italic") then
        setting.italic = true
      end

      if exists(attr.modifiers, "crossed_out") then
        setting.strikethrough = true
      end

      if exists(attr.modifiers, "reverse") then
        setting.reverse = true
      end
    end

    return setting
  end
end

local function hx_to_vim(hx_hls)
  local vim_hls = {}

  for key, val in pairs(hx_hls) do
    if type(val) == "string" then
      vim_hls[key] = attr_to_setting(t[val])
    end

    if type(val) == "table" then
      for _, v in ipairs(val) do
        if t[v] ~= nil then
          vim_hls[key] = attr_to_setting(t[v])
          break
        end
      end
    end
  end

  return vim_hls
end


local diff                   = {
  plus = attr_to_setting("diff.plus"),
  delta = attr_to_setting("diff.delta"),
  minus = attr_to_setting("diff.minus"),
}

local M                      = {}

---main highlight functions
M.main_highlights            = {}

---async highlight functions
M.async_highlights           = {}

---regular Vim syntax highlights
M.main_highlights.syntax     = function()
  local hx_hls = {
    Identifier   = "variable",
    Comment      = "comment",
    Keyword      = "keyword",
    Conditional  = { "keyword.control.conditional", "keyword.control", "keyword" },
    Function     = "function",
    Repeat       = { "keyword.control.repeat", "keyword.control", "keyword" },
    String       = "string",
    Type         = "type",
    StorageClass = { "keyword.storage.modifier", "keyword.storage", "keyword" }, -- static, register, volatile, etc.
    Structure    = "type",
    Constant     = "constant",
    Number       = { "constant.numeric.integer", "constant.numeric", "constant" },
    Statement    = "keyword",
    Label        = "label", -- case, default, etc.
    Operator     = "operator",
    Exception    = { "keyword.control.exception", "keyword.control", "keyword" },
    Macro        = { "function.macro", "function" },
    Typedef      = { "keyword.storage.type", "keyword.storage", "keyword" },
    Special      = { "string.special", "string" },
    SpecialChar  = "special",
    Tag          = "tag",
    Delimiter    = { "punctuation.delimiter", "punctuation" }, -- ;
    htmlLink     = { "markup.link.url", "markup.link", "markup" },
  }

  local link_hls = {
    SpecialComment = { link = "Comment" }, -- special things inside a comment
    Character      = { link = "Number" },
    Boolean        = { link = "Number" },
    Float          = { link = "Number" },
    Include        = { link = "Macro" },
    -- Define         = { link = "Macro" },
    -- PreProc        = { link = "Macro" },
    -- PreCondit   = { link = "Macro" },
    Debug          = { link = "Macro" },
    -- htmlH1         = { fg = m.cyan, bold = true },
    -- htmlH2         = { fg = m.red, bold = true },
    -- htmlH3         = { fg = m.green, bold = true },
  }

  -- TODO: apply the user set styles for these groups
  -- syntax_hls.Comment      = vim.tbl_extend("keep", syntax_hls.Comment, styles.comments)
  -- syntax_hls.Conditional  = vim.tbl_extend("keep", syntax_hls.Conditional, styles.keywords)
  -- syntax_hls.Function     = vim.tbl_extend("keep", syntax_hls.Function, styles.functions)
  -- syntax_hls.Identifier   = vim.tbl_extend("keep", syntax_hls.Identifier, styles.variables)
  -- syntax_hls.Keyword      = vim.tbl_extend("keep", syntax_hls.Keyword, styles.keywords)
  -- syntax_hls.Repeat       = vim.tbl_extend("keep", syntax_hls.Repeat, styles.keywords)
  -- syntax_hls.String       = vim.tbl_extend("keep", syntax_hls.String, styles.strings)
  -- syntax_hls.Type         = vim.tbl_extend("keep", syntax_hls.Type, styles.types)
  -- syntax_hls.Structure    = vim.tbl_extend("keep", syntax_hls.Structure, styles.types)
  -- syntax_hls.StorageClass = vim.tbl_extend("keep", syntax_hls.StorageClass, styles.keywords)

  local vim_hls = hx_to_vim(hx_hls)

  return vim.tbl_extend("force", vim_hls, link_hls)
end

---treesitter highlights
M.main_highlights.treesitter = function()
  local hx_treesitter_hls = {
    ["@type.builtin"]            = { "type.builtin", "type" },

    ["@variable"]                = "variable",
    ["@variable.builtin"]        = { "variable.builtin", "variable" },
    ["@field"]                   = { "variable.other", "variable" },
    ["@property"]                = { "variable.other", "variable" },
    ["@variable.parameter"]      = { "variable.other.member", "variable.other", "variable" },
    ["@variable.member"]         = { "variable.other.member", "variable.other", "variable" }, -- Fields
    ["@string.special.symbol"]   = { "string.special.symbol", "string.special", "string" },

    ["@function.builtin"]        = { "function.builtin", "function" },
    ["@function.macro"]          = { "function.macro", "function" },

    ["@function.method"]         = { "function.method", "function" },
    ["@function.method.call"]    = { "function.method", "function" },

    ["@constructor"]             = { "constructor", "function" },

    ["@keyword"]                 = "keyword",
    ["@keyword.directive"]       = { "keyword.directive", "keyword" },
    ["@keyword.storage"]         = { "keyword.storage", "keyword" },

    ["@constant"]                = "constant",
    ["@constant.builtin"]        = { "constant.builtin", "constant" },
    ["@constant.macro"]          = "constant",

    ["@macro"]                   = { "function.macro", "function" },
    ["@module"]                  = { "namespace", "label" },

    ["@string.escape"]           = { "constant.character.escape", "string" },
    ["@string.regexp"]           = { "string.regexp", "string" },
    ["@string.special"]          = { "string.special", "string" },

    ["@label"]                   = "label",
    ["@punctuation"]             = "punctuation",
    ["@punctuation.delimiter"]   = { "punctuation.delimiter", "punctuation" },
    ["@punctuation.bracket"]     = { "punctuation.bracket", "punctuation" },
    ["@punctuation.special"]     = { "punctuation.special", "punctuation" },

    ["@markup.title"]            = "markup.heading",
    ["@markup.heading"]          = "markup.heading",
    ["@markup.literal"]          = "markup.raw",
    ["@markup.link.url"]         = { "markup.link.url", "markup.link" },  -- urls, links and emails
    ["@markup.math"]             = { "markup.link.text", "markup.link" }, -- e.g. LaTeX math
    ["@markup.raw"]              = "markup.raw",                          -- e.g. inline `code` in Markdown
    ["@markup.environment"]      = "markup.raw",
    ["@markup.environment.name"] = "markup.raw",
    ["@tag"]                     = "tag",

    TreesitterContext            = { "ui.selection.primary", "ui.selection" },
    TreesitterContextLineNumber  = { "ui.linenr.selected", "ui.linenr" },
  }

  local treesitter_hls = {
    ["@error"]                    = { link = "Error" },

    ["@comment"]                  = { link = "Comment" },
    ["@comment.todo"]             = { link = "Comment" },
    ["@comment.error"]            = "error",
    ["@comment.warning"]          = "warning",
    ["@comment.hint"]             = "hint",
    ["@comment.note"]             = "info",

    ["@type"]                     = { link = "Type" },
    ["@type.definition"]          = { link = "Typedef" },
    ["@type.qualifier"]           = { link = "StorageClass" },

    ["@function"]                 = { link = "Function" },
    ["@function.call"]            = { link = "Function" },
    ["@keyword.coroutine"]        = { fg = p[t.keyword], italic = true },
    ["@keyword.operator"]         = { link = "@keyword" },
    ["@keyword.return"]           = { link = "@keyword" },
    ["@keyword.function"]         = { link = "@keyword" },
    ["@keyword.export"]           = { link = "@keyword" },

    ["@keyword.conditional"]      = { link = "Conditional" },
    ["@keyword.repeat"]           = { link = "Repeat" },
    ["@keyword.import"]           = { link = "Include" },
    ["@keyword.exception"]        = { link = "Exception" },

    ["@string"]                   = { link = "String" },
    ["@character"]                = { link = "Character" },
    ["@character.special"]        = { link = "SpecialChar" },

    ["@diff.plus"]                = { link = "DiffAdd" },
    ["@diff.minus"]               = { link = "DiffDelete" },
    ["@diff.delta"]               = { link = "DiffChange" },
    ["@attribute"]                = { link = "DiffChange" },

    -- ["@structure"]             = "type",
    ["@markup.underline"]         = { underline = true },
    ["@markup.emphasis"]          = { italic = true },
    ["@markup.strong"]            = { bold = true },
    ["@markup.strikethrough"]     = { strikethrough = true },
    ["@markup.link"]              = { link = "Tag" },          -- text references, footnotes, citations, etc.
    ["@markup.list"]              = { link = "Special" },
    ["@markup.list.checked"]      = { link = "@markup.list" }, -- checkboxes
    ["@markup.list.unchecked"]    = { link = "@markup.list" },
    ["@markup.warning"]           = "warning",
    ["@markup.danger"]            = "error",
    ["@tag.delimiter"]            = { link = "@punctuation.delimiter" },
    ["@tag.attribute"]            = { link = "Special" },
    ["@keyword.directive.define"] = { link = "@keyword.directive" },
    ["@operator"]                 = { link = "Operator" },
    ["@boolean"]                  = { link = "Boolean" },
    ["@number"]                   = { link = "Number" },
    ["@number.float"]             = { link = "Float" },
  }

  treesitter_hls = vim.tbl_extend("force", treesitter_hls, hx_to_vim(hx_treesitter_hls))

  -- Legacy highlights, for backward compatibility
  treesitter_hls["@parameter"] = treesitter_hls["@variable.parameter"]
  treesitter_hls["@field"] = treesitter_hls["@variable.member"]
  treesitter_hls["@namespace"] = treesitter_hls["@module"]
  treesitter_hls["@float"] = treesitter_hls["number.float"]
  treesitter_hls["@symbol"] = treesitter_hls["@string.special.symbol"]
  treesitter_hls["@string.regex"] = treesitter_hls["@string.regexp"]

  treesitter_hls["@text"] = treesitter_hls["@markup"]
  treesitter_hls["@text.strong"] = treesitter_hls["@markup.strong"]
  treesitter_hls["@text.emphasis"] = treesitter_hls["@markup.italic"]
  treesitter_hls["@text.underline"] = treesitter_hls["@markup.underline"]
  treesitter_hls["@text.strike"] = treesitter_hls["@markup.strikethrough"]
  treesitter_hls["@text.uri"] = treesitter_hls["@markup.link.url"]
  treesitter_hls["@text.math"] = treesitter_hls["@markup.math"]
  treesitter_hls["@text.environment"] = treesitter_hls["@markup.environment"]
  treesitter_hls["@text.environment.name"] = treesitter_hls["@markup.environment.name"]

  treesitter_hls["@text.title"] = treesitter_hls["@markup.heading"]
  treesitter_hls["@text.literal"] = treesitter_hls["@markup.raw"]
  treesitter_hls["@text.reference"] = treesitter_hls["@markup.link"]

  treesitter_hls["@text.todo.checked"] = treesitter_hls["@markup.list.checked"]
  treesitter_hls["@text.todo.unchecked"] = treesitter_hls["@markup.list.unchecked"]

  -- @text.todo is now for todo comments, not todo notes like in markdown
  treesitter_hls["@text.todo"] = treesitter_hls["comment.warning"]
  treesitter_hls["@text.warning"] = treesitter_hls["comment.warning"]
  treesitter_hls["@text.note"] = treesitter_hls["comment.note"]
  treesitter_hls["@text.danger"] = treesitter_hls["comment.error"]

  treesitter_hls["@method"] = treesitter_hls["@function.method"]
  treesitter_hls["@method.call"] = treesitter_hls["@function.method.call"]

  treesitter_hls["@text.diff.add"] = treesitter_hls["@diff.plus"]
  treesitter_hls["@text.diff.delete"] = treesitter_hls["@diff.minus"]

  treesitter_hls["@define"] = treesitter_hls["@keyword.directive.define"]
  treesitter_hls["@preproc"] = treesitter_hls["@keyword.directive"]
  treesitter_hls["@storageclass"] = treesitter_hls["@keyword.storage"]
  treesitter_hls["@conditional"] = treesitter_hls["@keyword.conditional"]
  treesitter_hls["exception"] = treesitter_hls["@keyword.exception"]
  treesitter_hls["@include"] = treesitter_hls["@keyword.import"]
  treesitter_hls["@repeat"] = treesitter_hls["@keyword.repeat"]

  if vim.fn.has("nvim-0.8.0") == 1 then
    return treesitter_hls
  else
    local treesitter_hls_old = {
      TSTypeBuiltin     = treesitter_hls["@type.builtin"],

      TSFuncBuiltin     = treesitter_hls["@function.builtin"],
      TSFuncMacro       = treesitter_hls["@function.macro"],
      TSConstructor     = treesitter_hls["@constructor"],

      TSType            = treesitter_hls["@type"],
      TSVariableBuiltin = treesitter_hls["@variable.builtin"],
      TSField           = treesitter_hls["@field"],
      TSSymbol          = treesitter_hls["@symbol"],

      TSKeyword         = treesitter_hls["@keyword"],

      TSConstant        = treesitter_hls["@constant"],
      TSConstantBuiltin = treesitter_hls["@constant.builtin"],
      TSConstantMacro   = treesitter_hls["@constant.macro"],

      TSMacro           = treesitter_hls["@macro"],
      TSNamespace       = treesitter_hls["@namespace"],

      TSStringEscape    = treesitter_hls["@string.escape"],
      TSStringRegex     = treesitter_hls["@string.regex"],
      TSStringSpecial   = treesitter_hls["@string.special"],

      TSPunct           = treesitter_hls["@punctuation"],
      TSPunctDelimiter  = treesitter_hls["@punctuation.delimiter"],
      TSPunctBracket    = treesitter_hls["@punctuation.bracket"],
      TSURI             = treesitter_hls["@text.uri"],
      TSTodo            = treesitter_hls["@text.todo"],
      TSTag             = treesitter_hls["@tag"],
      TSTagDelimiter    = treesitter_hls["@tag.delimiter"],
      TSTagAttribute    = treesitter_hls["@tag.attribute"],
    }

    return treesitter_hls_old
  end
end

---parts of the editor that get loaded right away
M.main_highlights.editor     = function()
  local hx_editor_hls = {
    Normal         = "ui.text",
    NormalFloat    = "ui.background",
    NormalContrast = "ui.window", -- a help group for contrast fileypes
    ColorColumn    = { "ui.virtual.ruler", "ui.virtual" },
    Conceal        = "ui.text",   -- Could not find relevant key in helix
    Cursor         = { "ui.cursor.primary", "ui.cursor" },
    ErrorMsg       = "error",
    Folded         = { "ui.cursorline.primary", "ui.cursorline" },
    FoldColumn     = { "ui.virtual.wrap", "ui.virtual" }, -- Very confusing, hacky solution for now
    LineNr         = "ui.linenr",
    CursorLineNr   = { "ui.linenr.selected", "ui.linenr" },
    ModeMsg        = { "ui.statusline.normal", "ui.statusline" }, -- 'showmode' message (e.g., "-- INSERT -- ")
    NonText        = { "ui.virtual.whitespace", "ui.virtual" },
    SignColumn     = { "ui.gutter", "ui.linenr" },
    StatusLine     = "ui.statusline",
    StatusLineNC   = { "ui.statusline.inactive" },
    TabLineSel     = { "ui.menu.selected", "ui.menu" },
    TabLine        = "ui.menu",
    Title          = "ui.menu",
    WarningMsg     = "warning",
    Whitespace     = { "ui.virtual.whitespace", "ui.virtual" },
    CursorLine     = { "ui.cursorline.primary", "ui.cursorline" },
    Todo           = "info",
    Ignore         = { "ui.text.inactive", "ui.text" },
    Underlined     = { "markup.link.url", "markup.link" }, -- FIXME: Use only colors from the theme, not underline
    Error          = "error",
  }

  local editor_hls = {
    TermCursor       = { link = "Cursor" }, -- cursor for the terminal
    CursorIM         = { link = "Cursor" }, -- like Cursor, but used when in IME mode
    DiffAdd          = { fg = diff.plus.fg, reverse = true },
    DiffChange       = { fg = diff.delta.fg },
    DiffDelete       = { fg = diff.minus.fg, reverse = true },
    DiffText         = { fg = diff.delta.fg, reverse = true },
    SpecialKey       = { link = "NonText" }, -- TODO: Don't know
    StatusLineTerm   = { link = "StatusLine" },
    StatusLineTermNC = { link = "StatusLineNC" },
    TabLineFill      = { link = "Tabline" },
    CursorColumn     = { link = "CursorLine" },

    -- TODO: color highlights
    -- Black            = { fg = m.black },
    -- Red              = { fg = m.red },
    -- Green            = { fg = m.green },
    -- Yellow           = { fg = m.yellow },
    -- Blue             = { fg = m.blue },
    -- Cyan             = { fg = m.cyan },
    -- Purple           = { fg = m.purple },
    -- Orange           = { fg = m.orange },
  }

  return vim.tbl_extend("force", editor_hls, hx_to_vim(hx_editor_hls))
end

---parts of the editor that get loaded asynchronously
M.async_highlights.editor    = function()
  local hx_editor_hls = {
    FloatBorder   = "ui.window",
    SpellBad      = { "diagnostic.error", "diagnostic" },
    SpellCap      = { "diagnostic.warning", "diagnostic" },
    SpellLocal    = { "diagnostic.hint", "diagnostic" },
    SpellRare     = { "diagnostic.info", "diagnostic" },
    Warnings      = "warning",
    healthError   = "error",
    healthSuccess = "info",
    healthWarning = "warning",
    Visual        = { "ui.selection.primary", "ui.selection" },
    Directory     = "ui.menu",
    MatchParen    = "ui.cursor.match",
    Question      = "warning", -- |hit-enter| prompt and yes/no questions
    QuickFixLine  = { "ui.menu.selected", "ui.menu" },
    Search        = { "ui.selection.primary", "ui.selection" },
    MoreMsg       = "hint",
    Pmenu         = "ui.menu",                         -- popup menu
    PmenuSel      = { "ui.menu.selected", "ui.menu" }, -- Popup menu: selected item.
    PmenuSbar     = "ui.menu.scroll",
    PmenuThumb    = "ui.menu.scroll",
    WildMenu      = { "ui.menu.selected", "ui.menu" }, -- current match in 'wildmenu' completion
    VertSplit     = "ui.window",
    WinSeparator  = "ui.window",
    diffAdded     = "diff.plus",
    diffRemoved   = "diff.minus",
  }

  local editor_hls = {
    NormalNC  = { link = "Normal" },
    VisualNOS = { link = "Visual" }, -- Visual mode selection when vim is "Not Owning the Selection".
    IncSearch = { link = "Search" },
    CurSearch = { link = "Search" },
    -- EndOfBuffer = { link = "NonText" }
    -- ToolbarLine   = { fg = e.fg, bg = e.bg_alt },
    -- ToolbarButton = { fg = e.fg, bold = true },
    -- NormalMode       = { fg = e.disabled }, -- Normal mode message in the cmdline
    -- InsertMode       = { link = "NormalMode" },
    -- ReplacelMode     = { link = "NormalMode" },
    -- VisualMode       = { link = "NormalMode" },
    -- CommandMode      = { link = "NormalMode" },
  }

  return vim.tbl_extend("force", editor_hls, hx_to_vim(hx_editor_hls))
end

-- these should be loaded right away because
-- some plugins like lualine.nvim inherit the colors
M.main_highlights.load_lsp   = function()
  local lsp_hls = {
    DiagnosticError       = { "diagnostic.error", "error" },
    DiagnosticWarn        = { "diagnostic.warning", "warning" },
    DiagnosticInformation = { "diagnostic.info", "info" },
    DiagnosticHint        = { "diagnostic.hint", "hint" },
  }

  return hx_to_vim(lsp_hls)
end

M.async_highlights.load_lsp  = function()
  local hx_lsp_hls = {
    DiagnosticUnderlineError = { "diagnostic.error", "error" },
    DiagnosticUnderlineWarn  = { "diagnostic.warning", "warning" },
    DiagnosticUnderlineInfo  = { "diagnostic.info", "info" },
    DiagnosticUnderlineHint  = { "diagnostic.hint", "hint" },
    LspReferenceText         = { "ui.cursorline.primary", "ui.cursorline" }, -- used for highlighting "text" references
    LspCodeLens              = { "diagnostic.hint", "hint" },
    LspInlayHint             = "ui.virtual.inlay-hint",
  }

  local lsp_hls = {
    -- Nvim 0.6. and up
    DiagnosticVirtualTextError                 = { link = "DiagnosticError" },
    DiagnosticFloatingError                    = { link = "DiagnosticError" },
    DiagnosticSignError                        = { link = "DiagnosticError" },
    DiagnosticVirtualTextWarn                  = { link = "DiagnosticWarn" },
    DiagnosticFloatingWarn                     = { link = "DiagnosticWarn" },
    DiagnosticSignWarn                         = { link = "DiagnosticWarn" },
    DiagnosticVirtualTextInfo                  = { link = "DiagnosticInfo" },
    DiagnosticFloatingInfo                     = { link = "DiagnosticInfo" },
    DiagnosticSignInfo                         = { link = "DiagnosticInfo" },
    DiagnosticVirtualTextHint                  = { link = "DiagnosticHint" },
    DiagnosticFloatingHint                     = { link = "DiagnosticHint" },
    DiagnosticSignHint                         = { link = "DiagnosticHint" },
    LspReferenceRead                           = { link = "LspReferenceText" }, -- used for highlighting "read" references
    LspReferenceWrite                          = { link = "LspReferenceText" }, -- used for highlighting "write" references

    ["@lsp.type.builtinType"]                  = { link = "@type.builtin" },
    ["@lsp.type.comment"]                      = { link = "@comment" },
    ["@lsp.type.boolean"]                      = { link = "@boolean" },
    ["@lsp.type.enum"]                         = { link = "@type" },
    ["@lsp.type.enumMember"]                   = { link = "@constant" },
    ["@lsp.type.escapeSequence"]               = { link = "@string.escape" },
    ["@lsp.type.formatSpecifier"]              = { link = "@punctuation" },
    ["@lsp.type.interface"]                    = { link = "Identifier" },
    ["@lsp.type.keyword"]                      = { link = "@keyword" },
    ['@lsp.type.class']                        = { link = "@type" },
    ["@lsp.type.namespace"]                    = { link = "@module" },
    ["@lsp.type.number"]                       = { link = "@number" },
    ["@lsp.type.operator"]                     = { link = "@operator" },
    ["@lsp.type.parameter"]                    = { link = "@variable.parameter" },
    ["@lsp.type.property"]                     = { link = "@property" },
    ["@lsp.type.selfKeyword"]                  = { link = "@variable.builtin" },
    ["@lsp.type.typeAlias"]                    = { link = "@type" },
    ["@lsp.type.unresolvedReference"]          = { link = "@error" },
    ["@lsp.typemod.class.defaultLibrary"]      = { link = "@type.builtin" },
    ["@lsp.typemod.enum.defaultLibrary"]       = { link = "@type.builtin" },
    ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "@constant.builtin" },
    ["@lsp.typemod.function.defaultLibrary"]   = { link = "@function.builtin" },
    ["@lsp.typemod.keyword.async"]             = { link = "@keyword.coroutine" },
    ["@lsp.typemod.macro.defaultLibrary"]      = { link = "@function.builtin" },
    ["@lsp.typemod.method.defaultLibrary"]     = { link = "@function.builtin" },
    ["@lsp.typemod.operator.injected"]         = { link = "@operator" },
    ["@lsp.typemod.string.injected"]           = { link = "@string" },
    ["@lsp.typemod.type.defaultLibrary"]       = { link = "@type.builtin" },
    ["@lsp.typemod.variable.defaultLibrary"]   = { link = "@variable.builtin" },
    ["@lsp.typemod.variable.injected"]         = { link = "@variable" },
  }

  return vim.tbl_extend("force", lsp_hls, hx_to_vim(hx_lsp_hls))
end

---function for setting the terminal colors
M.load_terminal              = function()
  -- TODO: terminal colors, maybe use helix's default colors
  -- vim.g.terminal_color_0 = m.black
  -- vim.g.terminal_color_1 = m.darkred
  -- vim.g.terminal_color_2 = m.darkgreen
  -- vim.g.terminal_color_3 = m.darkyellow
  -- vim.g.terminal_color_4 = m.darkblue
  -- vim.g.terminal_color_5 = m.darkpurple
  -- vim.g.terminal_color_6 = m.darkcyan
  -- vim.g.terminal_color_7 = m.white
  -- vim.g.terminal_color_8 = e.disabled
  -- vim.g.terminal_color_9 = m.red
  -- vim.g.terminal_color_10 = m.green
  -- vim.g.terminal_color_11 = m.yellow
  -- vim.g.terminal_color_12 = m.blue
  -- vim.g.terminal_color_13 = m.purple
  -- vim.g.terminal_color_14 = m.cyan
  -- vim.g.terminal_color_15 = m.white
end

-- TODO: apply plugin highlights
-- M.main_highlights            = vim.tbl_extend("keep", M.main_highlights, plugins.main_highlights)
-- M.async_highlights           = vim.tbl_extend("keep", M.async_highlights, plugins.async_highlights)

print(vim.inspect(M.main_highlights.syntax()))

return M
