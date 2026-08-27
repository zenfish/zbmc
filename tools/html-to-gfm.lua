local function plain_attr(el)
  el.attr = pandoc.Attr()
  return el
end

local function markdown_target(target)
  if target:match("^[%a][%w+.-]*:") or target:match("^//") or
     target:match("^#") or target:match("%.standalone%.html") then
    return target
  end
  local path, fragment = target:match("^(.-)(#.*)$")
  path = path or target
  fragment = fragment or ""
  return path:gsub("%.html$", ".md") .. fragment
end

function Div(el)
  return el.content
end

function Span(el)
  return el.content
end

function Header(el)
  return plain_attr(el)
end

function CodeBlock(el)
  return plain_attr(el)
end

function Link(el)
  el.target = markdown_target(el.target)
  return plain_attr(el)
end

function Image(el)
  el.src = markdown_target(el.src)
  return plain_attr(el)
end

function Table(el)
  return plain_attr(el)
end
