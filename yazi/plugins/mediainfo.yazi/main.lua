local M = {}

function M:peek(job)
	local child = Command("mediainfo")
		:arg(tostring(job.file.url))
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return
	end

	local output = child:wait_with_output()
	if not output or not output.status.success then
		return
	end

	local lines = {}
	for line in output.stdout:gmatch("[^\n]*") do
		local label, value = line:match("(.*[^ ])  +: (.*)")
		if label then
			table.insert(lines, ui.Line({
				ui.Span(label .. ": "):style(ui.Style():bold()),
				ui.Span(value):style(ui.Style():fg("blue")),
			}))
		elseif line ~= "" and line ~= "General" then
			table.insert(lines, ui.Line({
				ui.Span(line):style(ui.Style():fg("green")),
			}))
		end
	end

	ya.preview_widget(job, { ui.Text(lines):area(job.area) })
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		ya.emit("peek", {
			math.max(0, cx.active.preview.skip + job.units),
			only_if = job.file.url,
		})
	end
end

return M
