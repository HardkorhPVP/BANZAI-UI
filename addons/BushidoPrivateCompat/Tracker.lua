--[[
	BANZAI - Tracker.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	A compact Banzai objective tracker under the minimap: dark green glass, thin
	green -> purple top edge, small readable font, one obvious HIDE / SHOW
	button. It reads the quest log through Blizzard's supported API
	(C_QuestLog watches, objectives, super-tracking) and draws its own text, so
	no Blizzard or Kaliel's Tracker frame is touched. While it is on, Kaliel's
	Tracker is set to hidden through Kaliel's own visibility setting (done by
	BushidoPrivateRestore, recorded for rollback), so objectives are not shown
	twice. Left-click a quest: focus it (super-track); right-click: open it on
	the map (out of combat).

	0.5.0: exactly as wide as the minimap composition above it, its left and
	right edges on the visible edges of the minimap band (anchored to it);
	0.5.1 / 0.6.0: under the leaning minimap frame's bottom edge, as wide as it.

	0.7.0: readable groups instead of one block of text.
	  group       QUEST TITLE (brighter, larger), a thin separator line in the
	              Banzai gradient (the same language as the Details title
	              accents), then the objectives, then clear space
	  objectives  progress ("3/5") green when complete, light green while under
	              way, neutral when not started; the description light neutral;
	              "(Optional)" and finished objectives subdued; a quest ready to
	              turn in says so
	  height      grows with its content down to the space above the Banzai
	              Details frame (never over Details, Target, the action bars or
	              the bottom panel; MAX_HEIGHT at most); past that the content
	              scrolls: mouse wheel over the tracker, a slim position bar on
	              the right edge

	1.0.0: hovering a quest title or an objective shows its tooltip, left of
	the tracker (clear of the minimap): the full title, level / type, the
	quest log group (zone or category) or the world quest's zone, how it is
	tracked, bonus / optional, its timer where the game has one; for an
	objective its full text, progress and state. Quest log API only, nothing
	invented; clicks and the mouse-wheel scrolling work as before.
]]
local _, ns = ...
local Theme = ns.Theme

local Tracker = {}
ns.Tracker = Tracker

Tracker.WIDTH = 196     -- fallback: 185 map + 2 x (6 margin - 0.5 band edge)
Tracker.GAP = 14        -- below the minimap frame, clear of its corner bundle
Tracker.TOP = -253      -- fallback without the Banzai minimap frame
Tracker.RIGHT = -14.5
Tracker.MAX_HEIGHT = 560 -- upper bound; the space above the Details frame decides first
Tracker.CLEARANCE = 14  -- kept free above the Details frame / bottom panel
Tracker.HEADER = 24     -- OBJECTIVES title row
Tracker.PADDING = 6     -- under the scrolled content
Tracker.STEP = 42       -- one mouse-wheel notch
Tracker.SIZES = { title = 13, objective = 11 }
Tracker.SPACING = { title = 3, separator = 4, objective = 1, group = 9 }
local COLORS = {
	title = { 1.00, 0.92, 0.66 },
	focused = nil, -- the theme accent
	turnIn = { 0.55, 1.00, 0.50 },
	text = { 0.86, 0.89, 0.91 },
	muted = { 0.56, 0.60, 0.63 },
	done = { 0.42, 0.95, 0.45 },
	progress = { 0.74, 1.00, 0.55 },
	idle = { 0.80, 0.83, 0.86 },
}
Tracker.COLORS = COLORS

local function Safe(value)
	if issecretvalue and issecretvalue(value) then return nil end
	return value
end

local function Hex(c) return Theme:Hex(c) end
local function Paint(text, c) return '|cff' .. Hex(c) .. text .. '|r' end

-- Watched quests and world quests with their objectives (supported API only).
function Tracker:Collect()
	local list = {}
	local log = C_QuestLog
	if not log then return list end
	local seen = {}
	local function add(questID)
		questID = Safe(questID)
		if not questID or seen[questID] then return end
		seen[questID] = true
		local title = log.GetTitleForQuestID and Safe(log.GetTitleForQuestID(questID))
		if not title then return end
		local entry = { id = questID, title = title, complete = log.IsComplete and log.IsComplete(questID) or false, objectives = {} }
		local objectives = log.GetQuestObjectives and log.GetQuestObjectives(questID) or {}
		for _, o in ipairs(objectives) do
			local text = Safe(o.text)
			if text and text ~= '' then
				entry.objectives[#entry.objectives + 1] = { text = text, finished = o.finished and true or false,
					have = Safe(o.numFulfilled), need = Safe(o.numRequired), kind = Safe(o.type) }
			end
		end
		list[#list + 1] = entry
	end
	if log.GetNumQuestWatches and log.GetQuestIDForQuestWatchIndex then
		for i = 1, log.GetNumQuestWatches() or 0 do add(log.GetQuestIDForQuestWatchIndex(i)) end
	end
	if log.GetNumWorldQuestWatches and log.GetQuestIDForWorldQuestWatchIndex then
		for i = 1, log.GetNumWorldQuestWatches() or 0 do add(log.GetQuestIDForWorldQuestWatchIndex(i)) end
	end
	local focused = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and Safe(C_SuperTrack.GetSuperTrackedQuestID())
	for _, e in ipairs(list) do e.focused = (e.id == focused) end
	return list
end

-- One objective as coloured text: the progress part ("3/5", "45%") by its
-- state, the description light neutral, "(Optional)" subdued; a finished
-- objective is green and quieter.
function Tracker.ObjectiveText(o)
	local text = o.text
	local optional = string.find(text, '%(Optional%)') ~= nil
	text = string.gsub(text, '%s*%(Optional%)', '')
	local tail = optional and ('  ' .. Paint('(Optional)', COLORS.muted)) or ''
	if o.finished then
		return Paint(text, COLORS.done) .. tail, 'done'
	end
	-- "3/5 Thing" or "Thing: 3/5"
	local before, have, need, after = string.match(text, '^()(%d+)/(%d+)%s+(.+)$')
	if have then
		before = ''
	else
		before, have, need = string.match(text, '^(.-:?)%s+(%d+)/(%d+)$')
	end
	if have then
		local a, b = tonumber(have), tonumber(need)
		local state = (a >= b and 'done') or (a > 0 and 'progress') or 'idle'
		local progress = Paint(have .. '/' .. need, COLORS[state])
		if after then return progress .. ' ' .. Paint(after, COLORS.text) .. tail, state end
		return Paint(before, COLORS.text) .. ' ' .. progress .. tail, state
	end
	-- "Thing explored 45%"
	local pre, percent, post = string.match(text, '^(.-)(%d+%%)(.*)$')
	if percent then
		local p = tonumber(string.match(percent, '%d+'))
		local state = (p >= 100 and 'done') or (p > 0 and 'progress') or 'idle'
		return Paint(pre, COLORS.text) .. Paint(percent, COLORS[state]) .. Paint(post, COLORS.text) .. tail, state
	end
	return Paint(text, optional and COLORS.muted or COLORS.text) .. tail, 'text'
end

---------------------------------------------------------------------------
-- 1.0.0 tooltips (quest log API only; a detail the game does not give is left out)
---------------------------------------------------------------------------
local function Call(fn, ...)
	if type(fn) ~= 'function' then return nil end
	local ok, a, b = pcall(fn, ...)
	if not ok then return nil end
	return Safe(a), Safe(b)
end

local FREQUENCY = { [1] = 'Daily', [2] = 'Weekly' }

local function Clock(seconds)
	seconds = tonumber(seconds)
	if not seconds or seconds <= 0 then return nil end
	local h, m, s = math.floor(seconds / 3600), math.floor(seconds / 60) % 60, math.floor(seconds) % 60
	if h > 0 then return string.format('%dh %02dm', h, m) end
	return string.format('%dm %02ds', m, s)
end

-- level, kind, where, tracking and time of a quest, as the quest log has them
function Tracker.QuestDetails(questID)
	local log = C_QuestLog or {}
	local out = {}
	local index = Call(log.GetLogIndexForQuestID, questID)
	local info = index and Call(log.GetInfo, index)
	if type(info) == 'table' then
		out.level = Safe(info.level)
		out.frequency = FREQUENCY[Safe(info.frequency)]
		out.bonus = Safe(info.isTask) and true or nil
		out.campaign = (Safe(info.campaignID) or 0) > 0 or nil
		-- the quest log group above it: its zone or category
		for i = index - 1, 1, -1 do
			local header = Call(log.GetInfo, i)
			if type(header) == 'table' and Safe(header.isHeader) then out.group = Safe(header.title) break end
		end
	end
	local tag = Call(log.GetQuestTagInfo, questID)
	if type(tag) == 'table' then out.tag = Safe(tag.tagName) end
	out.world = Call(log.IsWorldQuest, questID) and true or nil
	if out.world or out.bonus then
		local map = C_TaskQuest and Call(C_TaskQuest.GetQuestZoneID, questID)
		local mapInfo = map and C_Map and Call(C_Map.GetMapInfo, map)
		if type(mapInfo) == 'table' then out.zone = Safe(mapInfo.name) end
		out.timeLeft = C_TaskQuest and Call(C_TaskQuest.GetQuestTimeLeftSeconds, questID)
	end
	if not out.timeLeft then
		local total, elapsed = Call(log.GetTimeAllowed, questID)
		if total and elapsed and total > 0 then out.timeLeft = total - elapsed end
	end
	local watch = Call(log.GetQuestWatchType, questID)
	local types = Enum and Enum.QuestWatchType
	if watch ~= nil then
		out.tracked = (types and watch == types.Automatic) and 'Tracked (automatically)' or 'Tracked'
	elseif out.world then
		out.tracked = 'Tracked (world quest)'
	end
	return out
end

function Tracker:Tip(line)
	local tip = line and line.tip
	if not (tip and tip.quest and Theme:DB().trackerTips ~= false and ns.Tooltip) then return false end
	local tt = ns.Tooltip:Begin(line, 'LEFT')
	if not tt then return false end
	local q, o = tip.quest, tip.objective
	local d = Tracker.QuestDetails(q.id)
	local muted, text = COLORS.muted, COLORS.text
	tt:AddLine(q.title, COLORS.title[1], COLORS.title[2], COLORS.title[3], true)
	local kind = {}
	if d.level then kind[#kind + 1] = 'Level ' .. d.level end
	local words = { d.tag, d.frequency, d.campaign and 'Campaign' or false, d.bonus and 'Bonus objective' or false }
	for i = 1, 4 do if words[i] then kind[#kind + 1] = words[i] end end -- (some are missing: no ipairs over holes)
	if #kind > 0 then tt:AddLine(table.concat(kind, '  -  '), muted[1], muted[2], muted[3]) end
	local where = d.zone or d.group
	if where then tt:AddDoubleLine(d.zone and 'Zone' or 'Quest log', where, muted[1], muted[2], muted[3], text[1], text[2], text[3]) end
	if d.tracked then tt:AddDoubleLine('Tracking', d.tracked .. (q.focused and ', focused' or ''), muted[1], muted[2], muted[3], text[1], text[2], text[3]) end
	local left = Clock(d.timeLeft)
	if left then tt:AddDoubleLine('Time left', left, muted[1], muted[2], muted[3], 1.00, 0.80, 0.20) end
	if o then
		tt:AddLine(' ')
		local optional = string.find(o.text, '%(Optional%)') ~= nil
		tt:AddLine(o.text, 1, 1, 1, true)
		if o.need and o.need > 0 and o.have then
			tt:AddDoubleLine('Progress', o.have .. ' / ' .. o.need, muted[1], muted[2], muted[3], text[1], text[2], text[3])
		end
		local state = o.finished and 'Complete' or 'In progress'
		local c = o.finished and COLORS.done or COLORS.progress
		tt:AddDoubleLine(optional and 'Optional objective' or 'Objective', state, muted[1], muted[2], muted[3], c[1], c[2], c[3])
	else
		local done = 0
		for _, ob in ipairs(q.objectives or {}) do if ob.finished then done = done + 1 end end
		if q.complete then
			tt:AddLine('Ready to turn in', COLORS.turnIn[1], COLORS.turnIn[2], COLORS.turnIn[3])
		elseif #(q.objectives or {}) > 0 then
			tt:AddDoubleLine('Objectives', done .. ' / ' .. #q.objectives .. ' complete', muted[1], muted[2], muted[3], text[1], text[2], text[3])
		end
		tt:AddLine(' ')
		tt:AddLine('Left-click: focus   Right-click: open on the map', 0.62, 1.00, 0.12)
	end
	ns.Tooltip:Finish(tt)
	return true
end

local function Line(self, i)
	local f = self.frame
	local line = f.lines[i]
	if not line then
		line = CreateFrame('Button', nil, f.body)
		line.text = line:CreateFontString(nil, 'OVERLAY')
		line.text:SetPoint('TOPLEFT')
		line.text:SetPoint('TOPRIGHT')
		line.text:SetJustifyH('LEFT')
		if line.text.SetWordWrap then line.text:SetWordWrap(true) end
		line:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
		line:SetScript('OnClick', function(btn, button)
			if not btn.questID or InCombatLockdown() then return end
			if button == 'RightButton' then
				if QuestMapFrame_OpenToQuestDetails then pcall(QuestMapFrame_OpenToQuestDetails, btn.questID) end
			elseif C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
				pcall(C_SuperTrack.SetSuperTrackedQuestID, btn.questID)
			end
		end)
		-- 1.0.0 tooltips: hover only; the line's clicks and the wheel are untouched
		line:SetScript('OnEnter', function(btn) Tracker:Tip(btn) end)
		line:SetScript('OnLeave', function(btn) if ns.Tooltip then ns.Tooltip:End(btn) end end)
		line:SetScript('OnHide', function(btn) if ns.Tooltip then ns.Tooltip:End(btn) end end)
		f.lines[i] = line
	end
	return line
end

-- the thin line under a quest title: Banzai gradient fading out to the right
local function Separator(self, i)
	local f = self.frame
	local sep = f.separators[i]
	if not sep then
		sep = f.body:CreateTexture(nil, 'ARTWORK')
		sep:SetTexture(Theme.WHITE)
		sep:SetHeight(1)
		f.separators[i] = sep
	end
	return sep
end

function Tracker:Build()
	if self.frame then return self.frame end
	local f = CreateFrame('Frame', 'BanzaiTracker', UIParent)
	f:SetFrameStrata('LOW')
	f:SetSize(self.WIDTH, 24)
	f:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', self.RIGHT, self.TOP)
	f.glass = f:CreateTexture(nil, 'BACKGROUND')
	f.glass:SetAllPoints()
	f.edges = {}
	for i = 1, 4 do
		local e = f:CreateTexture(nil, 'BORDER')
		e:SetTexture(Theme.WHITE)
		e:SetHeight(2)
		f.edges[i] = e
	end
	f.title = f:CreateFontString(nil, 'OVERLAY')
	f.title:SetPoint('TOPLEFT', f, 'TOPLEFT', 8, -6)
	f.toggle = CreateFrame('Button', 'BanzaiTrackerToggle', f)
	f.toggle:SetSize(46, 16)
	f.toggle:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -6, -4)
	f.toggle.text = f.toggle:CreateFontString(nil, 'OVERLAY')
	f.toggle.text:SetPoint('RIGHT')
	f.toggle:SetScript('OnClick', function() Tracker:SetCollapsed(not Theme:DB().trackerCollapsed) end)
	-- the objectives scroll inside a clipped area under the title row
	f.scroll = CreateFrame('ScrollFrame', 'BanzaiTrackerScroll', f)
	f.scroll:SetPoint('TOPLEFT', f, 'TOPLEFT', 8, -self.HEADER)
	f.scroll:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -8, self.PADDING)
	if f.scroll.SetClipsChildren then f.scroll:SetClipsChildren(true) end
	f.body = CreateFrame('Frame', nil, f.scroll)
	f.body:SetSize(self.WIDTH - 16, 1)
	if f.scroll.SetScrollChild then f.scroll:SetScrollChild(f.body) end
	-- slim position bar on the right edge (shown only while the content scrolls)
	f.track = f:CreateTexture(nil, 'ARTWORK')
	f.track:SetTexture(Theme.WHITE)
	f.track:SetWidth(2)
	f.thumb = f:CreateTexture(nil, 'OVERLAY')
	f.thumb:SetTexture(Theme.WHITE)
	f.thumb:SetWidth(2)
	local function wheel(_, delta) Tracker:Scroll(-(delta or 0) * Tracker.STEP) end
	f:SetScript('OnMouseWheel', wheel)
	f.scroll:SetScript('OnMouseWheel', wheel)
	f.lines, f.separators = {}, {}
	f.offset = 0
	for _, event in ipairs({ 'QUEST_WATCH_LIST_CHANGED', 'QUEST_LOG_UPDATE', 'QUEST_ACCEPTED', 'QUEST_REMOVED', 'QUEST_TURNED_IN', 'SUPER_TRACKING_CHANGED', 'PLAYER_ENTERING_WORLD',
		'INSTANCE_ENCOUNTER_ENGAGE_UNIT', 'ENCOUNTER_END' }) do
		pcall(f.RegisterEvent, f, event)
	end
	f:SetScript('OnEvent', function() Tracker:Schedule() end)
	self.frame = f
	return f
end

function Tracker:Schedule()
	if self.scheduled then return end
	self.scheduled = true
	C_Timer.After(0.2, function()
		Tracker.scheduled = false
		Tracker:Update()
	end)
end

function Tracker:SetCollapsed(collapsed)
	Theme:DB().trackerCollapsed = collapsed and true or false
	self:Update()
end

-- rectangle in UIParent units (nil without a layout)
local function Rect(region)
	if not (region and region.GetRect) then return nil end
	local l, b, w, h = region:GetRect()
	if type(l) ~= 'number' or type(b) ~= 'number' or type(h) ~= 'number' or Safe(l) == nil or Safe(b) == nil then return nil end
	return l, b, w, h
end

Tracker.RIGHT_FRAMES = {}
for i = 1, 8 do Tracker.RIGHT_FRAMES[#Tracker.RIGHT_FRAMES + 1] = 'ElvUF_Boss' .. i end
for i = 1, 5 do Tracker.RIGHT_FRAMES[#Tracker.RIGHT_FRAMES + 1] = 'ElvUF_Arena' .. i end

-- the tallest the tracker may be: from its top down to the Banzai Details
-- frame (or the bottom panel without it), keeping CLEARANCE; MAX_HEIGHT at most
function Tracker:MaxHeight()
	local f = self.frame
	local _, b, _, h = Rect(f)
	if not b then return self.MAX_HEIGHT end
	local top = b + h
	local floor = Theme:DB().barHeight or 32
	local details = ns.Compat and ns.Compat.detailsFrame
	if details and details.IsShown and details:IsShown() then
		local _, db, _, dh = Rect(details)
		if db then floor = math.max(floor, db + dh) end
	end
	-- boss frames share the right side during an encounter (0.9.0: arena enemy
	-- frames during a match): stay above them too
	for _, name in ipairs(Tracker.RIGHT_FRAMES) do
		local other = _G[name]
		if other and other.IsVisible and other:IsVisible() then
			local _, bb, _, bh = Rect(other)
			if bb and bb + bh < top then floor = math.max(floor, bb + bh) end
		end
	end
	return math.max(self.HEADER + 40, math.min(self.MAX_HEIGHT, top - floor - self.CLEARANCE))
end

-- scroll by `delta` units (positive = further down), clamped
function Tracker:Scroll(delta)
	local f = self.frame
	if not (f and f.overflow and f.overflow > 0) then return end
	f.offset = math.max(0, math.min(f.overflow, (f.offset or 0) + (delta or 0)))
	if f.scroll.SetVerticalScroll then f.scroll:SetVerticalScroll(f.offset) end
	self:UpdateThumb()
end

function Tracker:UpdateThumb()
	local f = self.frame
	local scrolls = f.overflow and f.overflow > 0 and not Theme:DB().trackerCollapsed
	f.track:SetShown(scrolls and true or false)
	f.thumb:SetShown(scrolls and true or false)
	if not scrolls then return end
	local view = f.view or 1
	local trackHeight = view
	local thumbHeight = math.max(14, trackHeight * view / (view + f.overflow))
	local y = (trackHeight - thumbHeight) * (f.offset / f.overflow)
	f.track:ClearAllPoints()
	f.track:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -3, -self.HEADER)
	f.track:SetHeight(trackHeight)
	f.thumb:ClearAllPoints()
	f.thumb:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -3, -self.HEADER - y)
	f.thumb:SetHeight(thumbHeight)
	Theme:Gradient(f.track, 'VERTICAL', { 1, 1, 1 }, { 1, 1, 1 }, 0.08, 0.08)
	local from = Theme:Accents()
	Theme:Gradient(f.thumb, 'VERTICAL', Theme.COLORS.violet, from, 0.9, 0.9)
end

function Tracker:Update()
	local f = self.frame
	if not (f and f:IsShown()) then return end
	local db = Theme:DB()
	local font = Theme:SmallFont()
	local from = Theme:Accents()
	local quests = self:Collect()
	f.title:SetFont(font, 12, 'OUTLINE')
	f.title:SetText(Theme:GradientText('OBJECTIVES', from, Theme.COLORS.violet) .. '  |cff9aa0aa' .. #quests .. '|r')
	f.toggle.text:SetFont(font, 11, 'OUTLINE')
	f.toggle.text:SetText(db.trackerCollapsed and '|cff9cff4dSHOW +|r' or '|cff9aa0aaHIDE -|r')

	local width = (f.GetWidth and f:GetWidth() or self.WIDTH) - 16
	f.body:SetWidth(width)
	local S, Z = self.SPACING, self.SIZES
	local y, n, s = 0, 0, 0
	f.groups = {}
	if not db.trackerCollapsed then
		-- tip: what the line's tooltip explains ({ quest, objective }), nil for none
		local function put(text, size, questID, indent, color, tip)
			n = n + 1
			local line = Line(self, n)
			line.text:SetFont(font, size, 'OUTLINE')
			line.text:SetText(text)
			if color then line.text:SetTextColor(color[1], color[2], color[3]) else line.text:SetTextColor(1, 1, 1) end
			line:ClearAllPoints()
			line:SetPoint('TOPLEFT', f.body, 'TOPLEFT', indent or 0, -y)
			line:SetPoint('TOPRIGHT', f.body, 'TOPRIGHT', -4, -y)
			local h = math.max(size + 2, line.text:GetStringHeight() or size)
			line:SetHeight(h)
			line.questID = questID
			line.tip = tip
			line:EnableMouse(questID ~= nil or (tip ~= nil and db.trackerTips ~= false))
			line:Show()
			y = y + h
			return line
		end
		for _, q in ipairs(quests) do
			local group = { quest = q.id, top = y }
			local color = (q.complete and COLORS.turnIn) or (q.focused and from) or COLORS.title
			group.title = put(q.title, Z.title, q.id, 0, color, { quest = q })
			y = y + S.title
			s = s + 1
			local sep = Separator(self, s)
			sep:ClearAllPoints()
			sep:SetPoint('TOPLEFT', f.body, 'TOPLEFT', 0, -y)
			sep:SetWidth(width - 4)
			Theme:Gradient(sep, 'HORIZONTAL', from, Theme.COLORS.violet, 0.85, 0)
			sep:Show()
			group.separator = sep
			y = y + 1 + S.separator
			group.objectives = {}
			if q.complete and #q.objectives == 0 then
				group.objectives[1] = put(Paint('Ready to turn in', COLORS.turnIn), Z.objective, nil, 6)
				y = y + S.objective
			end
			for _, o in ipairs(q.objectives) do
				local text, state = Tracker.ObjectiveText(o)
				local line = put(Paint('- ', COLORS.muted) .. text, Z.objective, nil, 6, nil, { quest = q, objective = o })
				line.state = state
				group.objectives[#group.objectives + 1] = line
				y = y + S.objective
			end
			group.bottom = y
			f.groups[#f.groups + 1] = group
			y = y + S.group
		end
		if #quests == 0 then put('No tracked objectives', Z.objective, nil, 0, COLORS.muted) end
	end
	for i = n + 1, #f.lines do f.lines[i]:Hide() end
	for i = s + 1, #f.separators do f.separators[i]:Hide() end
	f.scroll:SetShown(not db.trackerCollapsed)
	local content = math.max(1, y - (#quests > 0 and S.group or 0))
	f.body:SetHeight(content)
	f.content = content
	-- bounded: grow down to the available space, scroll beyond it
	local maxHeight = self:MaxHeight()
	local full = self.HEADER + content + self.PADDING
	local height = db.trackerCollapsed and 26 or math.min(maxHeight, full)
	f:SetHeight(height)
	f.view = height - self.HEADER - self.PADDING
	f.overflow = (not db.trackerCollapsed) and math.max(0, content - f.view) or 0
	f.offset = math.min(f.offset or 0, f.overflow)
	if f.scroll.SetVerticalScroll then f.scroll:SetVerticalScroll(f.offset) end
	for _, region in ipairs({ f, f.scroll }) do
		if region.EnableMouseWheel then region:EnableMouseWheel(f.overflow > 0) end
	end
	self:UpdateThumb()
end

-- under the minimap composition, as wide as its bottom edge (band edge to band edge)
function Tracker:Place()
	local f = self.frame
	if not f then return end
	local Compat = ns.Compat
	local map = Compat and Compat.minimapFrame
	local outer = (Compat and Compat.BAND and Compat.BAND.outer) or 0.5
	f:ClearAllPoints()
	local width = self.WIDTH
	if map and map.bw then
		-- 0.6.0: the minimap frame is a parallelogram; its bottom edge starts
		-- Shift(bottom) from the frame's left side and is one row wide
		local row = Compat.RowWidth and Compat.RowWidth(map) or map.bw
		local left = Compat.Shift and Compat.Shift(map, map.bh) or 0
		width = row - 2 * outer
		f:SetPoint('TOPLEFT', map, 'BOTTOMLEFT', left + outer, -self.GAP)
	else
		f:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', self.RIGHT, self.TOP)
	end
	f:SetWidth(width)
	for i, e in ipairs(f.edges) do
		e:ClearAllPoints()
		e:SetPoint('TOPLEFT', f, 'TOPLEFT', (i - 1) * width / 4, 0)
		e:SetWidth(width / 4 + 0.5)
	end
end

function Tracker:Paint()
	local f = self.frame
	if not f then return end
	Theme:Glass(f.glass)
	local stops = Theme:Stops('h')
	for i, e in ipairs(f.edges) do
		Theme:Gradient(e, 'HORIZONTAL', Theme:ColorAt(stops, (i - 1) / 4), Theme:ColorAt(stops, i / 4), 0.95, 0.95)
	end
end

function Tracker:Refresh()
	local db = Theme:DB()
	local active = ns.Compat and ns.Compat.Active and ns.Compat.Active()
	local show = active and db.tracker and true or false
	if show and not self.frame then self:Build() end
	if not self.frame then return end
	self.frame:SetShown(show)
	if show then
		self:Place()
		self:Paint()
		self:Update()
	end
end
