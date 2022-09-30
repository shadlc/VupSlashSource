module("extensions.zzsystem", package.seeall)
extension=sgs.Package("zzsystem")
--extension = sgs.Package("zzsystem", sgs.Package_GeneralPack)

dlc = true --武将解锁系统（每5场游戏解锁1名隐藏武将）+记录胜率
show_winrate = true --显示胜率（颜神黑科技基础，在武将一览的高达杀武将第一行前可见）
achievement_system = false --成就


--狂野模式开关
--记得把VupV0.lua里的也设置为true
wild_mode = false	--狂野模式！！（仅限服务器用，所有隐藏角色可选）



function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then io.close(f) return true else return false end
end

datacount = "datacount.dll"			--扩展名什么都行
datadlc = "datadlc.dll"		--扩展名什么都行
server_data = "server_data.dll"		--检查是否为服务器用

if not file_exists(datacount) then	--检查/创建datacount
	local f = assert(io.open(datacount,'w'))
	io.close(f)
end

if not file_exists(datadlc) then	--检查/创建datadlc
	local f = assert(io.open(datadlc,'w'))
	io.close(f)
end

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

--[[function getWinner(victim)
    local room = victim:getRoom()
    local winner = ""

    if room:getMode() == "06_3v3" then
        local role = victim:getRoleEnum()
        if role == sgs.Player_Lord then
			winner = "renegade+rebel"
        elseif role == sgs.Player_Renegade then
			winner = "lord+loyalist"
        end
    elseif room:getMode() == "06_XMode" then
        local role = victim:getRole()
        local leader = victim:getTag("XModeLeader"):toPlayer()
        if leader:getTag("XModeBackup"):toStringList():isEmpty() then
            if role:startsWith("r") then
                winner = "lord+loyalist"
            else
                winner = "renegade+rebel"
			end
        end
	elseif room:getTag("InHuangLvMode"):toBool() then	--对接黄绿
		local alives = room:getAlivePlayers()
		local hasRebel = false
		local hasLoyalist = false
		for _,p in sgs.qlist(alives) do
			if p:getRole() == "loyalist" or p:getRole() == "lord" then
				hasLoyalist = true
			elseif p:getRole() == "rebel" then
				hasRebel = true
			end
		end
		if hasRebel and not hasLoyalist then
			winner = "rebel"
		elseif hasLoyalist and not hasRebel then
			winner = "loyalist"
		else
			winner = ""
		end
    elseif room:getMode() == "08_defense" then
        local alive_roles = room:aliveRoles(victim)
        if not table.contains(alive_roles, "loyalist") then
            winner = "rebel"
        elseif not table.contains(alive_roles, "rebel") then
            winner = "loyalist"
		end
    elseif sgs.GetConfig("EnableHegemony", true) then
        local has_anjiang, has_diff_kingdoms = false, false
        local init_kingdom = ""
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:property("basara_generals"):toString() ~= "" then
                has_anjiang = true
			end
            if init_kingdom:isEmpty() then
                init_kingdom = p:getKingdom()
            elseif init_kingdom ~= p:getKingdom() then
                has_diff_kingdoms = true
			end
        end

        if not has_anjiang and not has_diff_kingdoms then
            local winners = {}
            local aliveKingdom = room:getAlivePlayers():first():getKingdom()
            for _,p in sgs.qlist(room:getPlayers()) do
                if p:isAlive() then
					table.insert(winners, p:objectName())
				end
                if p:getKingdom() == aliveKingdom then
                    local generals = p:property("basara_generals"):toString():split("+")
                    if #generals and sgs.GetConfig("Enable2ndGeneral", false) then continue end
                    if #generals > 1 then continue end

                    --if someone showed his kingdom before death,
                    --he should be considered victorious as well if his kingdom survives
                    table.insert(winners, p:objectName())
                end
            end
            winner = table.concat(winners, "+")
        end
    else
        local alive_roles = room:aliveRoles(victim)
        local role = victim:getRoleEnum()
        if role == sgs.Player_Lord then
            if #alive_roles == 1 and alive_roles[1] == "renegade" then
                winner = room:getAlivePlayers():first():objectName()
            else
                winner = "rebel"
            end
        elseif role == sgs.Player_Rebel or role == sgs.Player_Renegade then
            if not table.contains(alive_roles, "rebel") and not table.contains(alive_roles, "renegade") then
                winner = "lord+loyalist"
            end
        else
        end
    end

    return winner
end]]

function RecordUnlockGenerals(player, general_name)
	local general = sgs.Sanguosha:getGeneral(general_name)
	if general and general:isBonus() then
		player:getRoom():setPlayerMark(player, "unlock_"..general_name.."-Keep", 1)		--结尾为-Keep的标记不会在角色死亡时被清除
	end
end

saveItem = function(item_type, add_num)
	local file = io.open(datadlc, "r")
	local tt = {}
	if file ~= nil then
		tt = file:read("*all"):split("\n")
		file:close()
	end
	
	local exist, repeated = false, false
	local record = assert(io.open(datadlc, "w"))
    for d,item in pairs(tt) do
		local s = item:split("=")
		local n = tonumber(s[2])
		if s[1] == item_type then
			if n > 0 then repeated = true end
			n = n + add_num
			exist = true
		end
		record:write(s[1] .. "=" .. n)
		if d ~= #tt or not exist then
			record:write("\n")
		end
    end
	
	if not exist then
		record:write(item_type .. "=" .. add_num)
	end
	
    record:close()
	return repeated
end

haveItem = function(item_type)
	local file = io.open(datadlc, "r")
	local tt = {}
	if file ~= nil then
		tt = file:read("*all"):split("\n")
		file:close()
	end
	
	for _,item in pairs(tt) do
		local s = item:split("=")
		if s[1] == item_type and tonumber(s[2]) > 0 then
			return true
		end
	end
	return false
end

existItem = function(item_type)
	local file = io.open(datadlc, "r")
	local tt = {}
	if file ~= nil then
		tt = file:read("*all"):split("\n")
		file:close()
	end
	
	for _,item in pairs(tt) do
		local s = item:split("=")
		if s[1] == item_type then
			return true
		end
	end
	return false
end


--【武将解锁系统】
if dlc then
	--file = assert(io.open(datacount, "r"), "在根目录创建一个空的g.lua档案即可解决问题poi")
	local file = io.open(datacount, "r")
	t = {}
	if file ~= nil then
		t = file:read("*all"):split("\n")
		file:close()
	end
end

function getOriginGeneral(p)
	for _, mark in sgs.list(p:getMarkNames()) do
		if p:getMark(mark) == 0 then continue end
		local prefix = "original_general_"
		if string.len(prefix) <= string.len(mark) and string.sub(mark, 1, string.len(prefix)) == prefix then
			return string.sub(mark, string.len(prefix)+1, -1)
		end
	end
	return nil
end

function getOriginGeneral2(p)
	for _, mark in sgs.list(p:getMarkNames()) do
		if p:getMark(mark) == 0 then continue end
		local prefix = "original_general2_"
		if string.len(prefix) <= string.len(mark) and string.sub(mark, 1, string.len(prefix)) == prefix then
			return string.sub(mark, string.len(prefix)+1, -1)
		end
	end
	return nil
end

saveRecord = function(player, record_table, record_type) --record_type: 0. +1 gameplay , 1. +1 win , 2. +1 win & +1 gameplay
	assert(record_type >= 0 and record_type <= 2, "record_type should be 0, 1 or 2")
	local tt = record_table
	local extra_unlock = {}
	local win = {}
	local times = {}
	for id,item in pairs(tt) do
		local s = item:split("=")
		tt[id] = s[1]
		local pr = s[2]:split("/")
		table.insert(win, tonumber(pr[1]))
		table.insert(times, tonumber(pr[2]))
	end
	if not table.contains(tt, "GameTimes") then
		table.insert(tt, "GameTimes")
		table.insert(win, 0)
		table.insert(times, 0)
	end
	local all = sgs.Sanguosha:getLimitedGeneralNames()
	--local all = sgs.Sanguosha:getAllGeneralNames()
	local banned_kingdom = {"wei","shu","wu","qun","god"}
	for _,name in pairs(all) do
		if not table.contains(banned_kingdom, sgs.Sanguosha:getGeneral(name):getKingdom()) and not table.contains(tt, name) then
			table.insert(tt, name)
			table.insert(win, 0)
			table.insert(times, 0)
		end
	end
	
	local record2 = assert(io.open(datacount, "w"))
	
	local katya_unlock_count = 0	--解锁卡缇娅β所需场次计数
	local katya_unlock_generals = {"huajianxili_sorry", "shixiaoya_xianyadan", "nia_youeryuanyuanzhang"}
	
	for d,text in pairs(tt) do
		local m = win[d]
		local n = times[d]
		
		local name = player:getGeneralName()
		
		local name2 = ""
		if player:getGeneral2() then
			name2 = player:getGeneral2Name()
		end
		
		--[[if name == "ximoyou_king" then name = "ximoyou_jiweimowang" end		--西魔幽·王胜率计入西魔幽·魔
		if name2 == "ximoyou_king" then name2 = "ximoyou_jiweimowang" end
		
		if name == "xiaheyi_king" then name = "xiaheyi_yinyangshi" end		--夏鹤仪·王胜率计入夏鹤仪·阴
		if name2 == "xiaheyi_king" then name2 = "xiaheyi_yinyangshi" end
		
		if name == "bijujieyi_senluozhilantu2" then name = "bijujieyi_senluozhilantu" end		--碧居结衣复苏形态胜率校正
		if name2 == "bijujieyi_senluozhilantu2" then name2 = "bijujieyi_senluozhilantu2" end
		
		if name == "newzhan_small" then name = "newzhan" end		--新戦彩蛋变身
		if name2 == "newzhan_small" then name2 = "newzhan" end
		
		if name == "xiaorou_cpmode" then name = "xiaorou_rhoxingai" end		--CP小柔
		if name2 == "xiaorou_cpmode" then name2 = "xiaorou_rhoxingai" end
		
		if name == "tongguhesha_cpmode" then name = "tongguhesha_xiuhexuemo" end		--CP桐谷和纱
		if name2 == "tongguhesha_cpmode" then name2 = "tongguhesha_xiuhexuemo" end]]
		
		if sgs.Sanguosha:translate("parent:"..name) ~= "parent:"..name then name = sgs.Sanguosha:translate("parent:"..name) end	--衍生角色胜率计入本体
		if sgs.Sanguosha:translate("parent:"..name2) ~= "parent:"..name2 then name2 = sgs.Sanguosha:translate("parent:"..name) end
		
		local original_general = getOriginGeneral(player)
		if original_general and original_general ~= "" then	--角色变化后，记录变化前角色的胜率
			name = original_general
		end
		local original_general2 = getOriginGeneral2(player)
		if original_general2 and original_general2 ~= "" then
			name2 = original_general2
		end
		
		if text == "GameTimes" or name == text or (name2 ~= "" and name2 == text and name ~= name2) then
			if record_type ~= 0 then -- record_type 1 or 2
				m = m + 1
			end
			if record_type ~= 1 then -- record_type 0 or 2
				n = n + 1
			end
		end
		
		local input = text.."="..tostring(m).."/"..tostring(n)
		t[d] = input
		record2:write(input)
		if d ~= #tt then
			record2:write("\n")
		end
		
		--按场次解锁角色
		--卡缇娅β场次计数
		if n > 0 and table.contains(katya_unlock_generals, text) then
			katya_unlock_count = katya_unlock_count + n
		end
	end
	
	--卡缇娅β解锁
	if katya_unlock_count >= 15 and not table.contains(extra_unlock, "katya_if") then
		table.insert(extra_unlock, "katya_if")
	end
	
	record2:close()
	return extra_unlock
end

refreshUnlockRecord = function(player, extra_unlock)
	local file = io.open(datadlc, "r")
	local unlock_list = {}
	if file ~= nil then
		unlock_list = file:read("*all"):split("\n")
		file:close()
	end
	
	local record = assert(io.open(datadlc, "w"))
	--local unlock_list = player:getTag("UnlockGeneralNames"):toString():split("+")
	--local unlock_list = {}
	
	local all_generals = sgs.Sanguosha:getAllGeneralNames()
	for _, general_name in ipairs(all_generals) do
		local general = sgs.Sanguosha:getGeneral(general_name)
		if general and general:isBonus() and player:getMark("unlock_"..general_name.."-Keep") > 0 and not table.contains(unlock_list, general_name) then
			table.insert(unlock_list, general_name)
		end
	end
	if extra_unlock then
		for _, general_name in ipairs(extra_unlock) do
			local general = sgs.Sanguosha:getGeneral(general_name)
			if general and general:isBonus() and not table.contains(unlock_list, general_name) then
				table.insert(unlock_list, general_name)
			end
		end
	end
	
	local print_nextline = false
	for _, unlock_name in ipairs(unlock_list) do
		if print_nextline then
			record:write("\n")
		end
		record:write(unlock_name)
		print_nextline = true
	end
	record:close()
end

--local recorded = false

gdsrecordcard = sgs.CreateSkillCard{
	name = "gdsrecord",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	about_to_use = function(self, room, use)
	end
}

gdsrecordvs = sgs.CreateZeroCardViewAsSkill{
	name = "gdsrecord",
	response_pattern = "@@gdsrecord!",
	view_as = function(self)
		if not sgs.Self:hasFlag("datacount_saved") then
			sgs.Self:setFlags("datacount_saved")
			local file = io.open(datacount, "r")
			local tt = {}
			if file ~= nil then
				tt = file:read("*all"):split("\n")
				file:close()
			end
			local extra_unlock = saveRecord(sgs.Self, tt, sgs.Self:getMark("record_type"))
			refreshUnlockRecord(sgs.Self, extra_unlock)
			--recorded = true
		end
		return gdsrecordcard:clone()
	end
}

gdsrecord = sgs.CreateTriggerSkill{
--[[Rule: 1. single mode +1 gameplay when game STARTED & +1 win (if win) when game FINISHED;
		2. online mode +1 gameplay & +1 win (if win) simultaneously when game FINISHED;
		3. single mode escape CAN +1 gameplay, online mode escape CANNOT +1 gameplay;
		4. +1 win (if win) when game FINISHED (no escape);
		5. online mode trust when game FINISHED CANNOT +1 neither gameplay nor win
		
	规则：1. 单机模式在游戏开始时+1游玩次数 & 在游戏结束时+1胜利次数（如果胜利）；	为了兼容联动大作战（黄绿）的换将，现在也改成游戏结束时+1
		2. 联机模式在游戏结束时同时+1游玩次数 & +1胜利次数（如果胜利）；
		3. 单机模式逃跑可以+1游玩次数，联机模式逃跑则不能+1游玩次数；
		4. 游戏结束时依然存在的玩家（没有逃跑）才会+1胜利次数（如果胜利）；
		5. 联机模式在游戏结束时托管的玩家不会记录游玩次数和胜利次数
]]
	name = "gdsrecord",
	events = {--[[sgs.DrawInitialCards, sgs.GameOverJudge,]] sgs.BeforeGameOver},
	global = true,
	view_as_skill = gdsrecordvs,
	can_trigger = function(self, player)
	    return dlc == true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()		
		--[[if event == sgs.DrawInitialCards then
			if player:getMark("@coin") > 0 then return false end
			if player:objectName() == room:getOwner():objectName() then
				local ip = room:getOwner():getIp()
				if ip ~= "" and string.find(ip, "127.0.0.1") then
					saveRecord(room:getOwner(), t, 0)
				end
			end
		else]]
			--[[if room:getMode() == "04_boss" and player:isLord()
				and sgs.GetConfig("BossModeEndless", false) or room:getTag("BossModeLevel"):toInt() < sgs.GetConfig("BossLevel", 0) - 1 then
					return false
				end
			if room:getMode() == "02_1v1" then
				local list = player:getTag("1v1Arrange"):toStringList()
				local rule = sgs.GetConfig("1v1/Rule", "2013")
				local n = 0
				if rule == "2013" then n = 3 end
				if list:length() > n then return false end
			end

			local winner = getWinner(player)]] -- player is victim
			local winner = data:toString()
			if winner ~= "" then
				--[[local ip = room:getOwner():getIp()
				if ip ~= "" and string.find(ip, "127.0.0.1") then
					saveRecord(room:getOwner(), t, 0)
					if string.find(winner, room:getOwner():getRole()) or string.find(winner, room:getOwner():objectName()) then
						saveRecord(room:getOwner(), t, 1)
					end
				else]]
					for _,p in sgs.qlist(room:getAllPlayers(true)) do
						if p:getState() == "online" or p:getState() == "trust" then
							if string.find(winner, p:getRole()) or string.find(winner, p:objectName()) then
								room:setPlayerMark(p, "record_type", 2)
								if p:getRole() == "renegade" then
									RecordUnlockGenerals(p, "newzhan")	--内奸胜利解锁新戦
								end
								if p:getGeneralName() == "wuqian_daweiba" and not p:isKongcheng() then
									local all_slash = true
									for _,cd in sgs.qlist(p:getHandcards()) do
										if not cd:isKindOf("Slash") then
											all_slash = false
											break
										end
									end
									if all_slash then
										RecordUnlockGenerals(p, "wuqian_wushuming")	--大尾巴满手杀胜利解锁无鼠名
									end
								end
								if p:getGeneralName() == "jinghua" and not p:faceUp() then
									RecordUnlockGenerals(p, "jinghua_beta")	--京华翻面胜利解锁京华β
								end
								if p:getGeneralName() == "linglaiguang_shengsixiangyi" and p:getMaxHp() == 1 then
									RecordUnlockGenerals(p, "tianyexuenai_shengsixiangyi")	--绫濑光1上限胜利解锁天野雪奈
								end
							else
								room:setPlayerMark(p, "record_type", 0)
							end
						end
					end
					for _,p in sgs.qlist(room:getAllPlayers(true)) do
						if p:getState() == "online" or p:getState() == "trust" then
							room:setPlayerMark(p, "Response_Time_Fix", 5000)	--读条时间固定5秒
							room:askForUseCard(p, "@@gdsrecord!", "@gdsrecord")
							room:setPlayerMark(p, "Response_Time_Fix", 0)
							room:setPlayerFlag(p, "-datacount_saved")
							room:setPlayerProperty(p, "state", sgs.QVariant("online"))
						end
					end
					--if not recorded then
						if file_exists(server_data) then		--检查是否为服务器端（文件是否存在），并记录胜率
							for _,p in sgs.qlist(room:getAllPlayers(true)) do
								saveRecord(p, t, 0)
								if string.find(winner, p:getRole()) or string.find(winner, p:objectName()) then
									saveRecord(p, t, 1)
								end
							end
					--	else
					--		saveRecord(room:getOwner(), t, 0)
					--		if string.find(winner, room:getOwner():getRole()) or string.find(winner, room:getOwner():objectName()) then
					--			saveRecord(room:getOwner(), t, 1)
					--		end
						end
					--end
					--recorded = false
				--end
			end
		--end
	end,
	priority = 3,
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("gdsrecord") then skills:append(gdsrecord) end
sgs.Sanguosha:addSkills(skills)


--【显示胜率】（续页底）
if show_winrate then
	winshow = sgs.General(extension, "winshow", "", 0, true, true, true)	--已制作新的胜率系统，暂时隐藏
	winshow:setGender(sgs.General_Sexless)
	winrate = sgs.CreateMasochismSkill{
		name = "winrate",
		on_damaged = function() 
		end
	}
	winshow:addSkill(winrate)
end

--【显示成就】（续页底）
if achievement_system then
	itemshow = sgs.General(extension, "itemshow", "", 0, true, true, false)
	itemshow:setGender(sgs.General_Sexless)
	itemnum = sgs.CreateMasochismSkill{
		name = "itemnum",
		on_damaged = function() 
		end
	}
	itemshow:addSkill(itemnum)
end

--【成就判定】
if dlc then
end

--【隐藏武将技能&翻译表】

--【解锁隐藏武将】
if dlc then
	local file = io.open(datadlc, "r")
	if file ~= nil then
		--local times = tonumber(t[1]:split("/")[2])	--获取游玩次数
	end
end




--【显示胜率】（置于页底以确保武将名翻译成功）
if show_winrate then
	local g_property = "<font color='red'><b>技术提供：高达杀制作组。玩一局来开启胜率系统~</b></font>"
	if dlc then
		if t[1] then
			g_property = ""
			local x, y = 0, 0
			for i,a in ipairs(t) do
				local str = a:split("=")
				local first = str[1]
				local second = str[2]
				local rate = second:split("/")
				if rate[2] == "0" then
					rate = "--"
				else
					local round = function(num, idp)
						local mult = 10^(idp or 0)
						return math.floor(num * mult + 0.5) / mult
					end
					rate = round(rate[1]/rate[2]*100).."%"
				end
				if first == "GameTimes" then
					g_property = g_property.."\n".."<b>总胜率</b>"
					x, y = second, rate
				else
					g_property = g_property.."\n"..sgs.Sanguosha:translate(first)
				end
				g_property = g_property.." = "..second.." <b>("..rate..")</b>"
				if i == #t then
					g_property = g_property.."\n".."<b>总胜率</b>"
					g_property = g_property.." = "..x.." <b>("..y..")</b>"
				end
			end
		end
		g_property = g_property.."<font color='purple'>\n<b>更新胜率信息以及解锁彩蛋</b>请关闭重开游戏</font>"
		g_property = g_property.."<font color='blue'>\n<b>存档记录清零</b>请删除根目录下<b>datacount.dll</b>文件<font color='red'>\n<b>注意</b>：记录清零会导致失去已解锁彩蛋</font>"
		g_property = g_property.."<font color='blue'>\n<b>移植存档记录</b>请移植根目录下<b>datacount.dll</b>文件</font>"
	end
	sgs.LoadTranslationTable{
		["zzsystem"] = "系统&彩蛋",
		["winshow"] = "胜率",
		["#winshow"] = "玩家资讯",
		["designer:winshow"] = "技术提供:高达杀制作组",
		["cv:winshow"] = "",
		["illustrator:winshow"] = "",
		["winrate"] = "胜率",
		[":winrate"] = g_property,
		
		["@gdsrecord"] = "请点击“确定”存档<br/>（按钮为灰色也需要点击）",
		["~gdsrecord"] = "点击确定 或 按ENTER",
	}
end

--完全隐藏三国杀本家的角色

--local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
local all_generals = sgs.Sanguosha:getAllGeneralNames()
local banned_kingdom = {"wei","shu","wu","qun","god","die"}
for _,name in pairs(all_generals) do
	local general = sgs.Sanguosha:getGeneral(name)
	if table.contains(banned_kingdom, general:getKingdom()) then
		general:setHidden(true)
		general:setTotallyHidden(true)
	end
end

--解锁彩蛋角色

local file = io.open(datadlc, "r")
local characters = {}
if file ~= nil then
	characters = file:read("*all"):split("\n")
	file:close()
end
for _,name in pairs(characters) do
	local general = sgs.Sanguosha:getGeneral(name)
	if general then
		if general:isHidden() then
			general:setHidden(true)
		end
		general:setTotallyHidden(false)
	end
end

--狂野模式！！（仅限服务器用，所有隐藏角色可选）

if wild_mode then
	local all_generals = sgs.Sanguosha:getAllGeneralNames()
	for _,name in pairs(all_generals) do
		local general = sgs.Sanguosha:getGeneral(name)
		if general:isBonus() then
			general:setHidden(false)
			general:setTotallyHidden(false)
		end
	end
end

--【扭蛋、彩蛋模式】（置于页底以确保武将名翻译成功）

sgs.LoadTranslationTable{
	--[[
	["$achievement_unlock"] = "恭喜你，解锁了“%arg”成就",
	["$achievement_unlock_g"] = "隐藏角色 %arg 已解锁，重启游戏可用~",
	
	[""] = "肝肠寸断",
	["-detail"] = "累计进行15场游戏",
	["-detail"] = "肝肠寸断达成奖励",
	]]
}

achievement = {"ach1", "ach2", "ach3",
				"award1", "award2", "award3"}

if achievement_system then
	
	for _,sk in pairs(achievement) do
		if not existItem(sk) then
			saveItem(sk, 0)
		end
	end
	
	local file = io.open(datadlc, "r")
	local tt = {}
	if file ~= nil then
		tt = file:read("*all"):split("\n")
		file:close()
	end
	
	local g2_property = ""
	g2_property = g2_property .. "\n\n<b>成就</b>："
	
	for i,a in pairs(tt) do
		local s = a:split("=")
		if string.find(s[1], "_achievement") then
			g2_property = g2_property .. "\n" .. sgs.Sanguosha:translate(s[1]) .. ": "
			if s[2] == "0" then
				g2_property = g2_property .. "<font color='grey'>未解锁</font>"
			else
				g2_property = g2_property .. "<font color='red'>已解锁</font>" .. "<font color='purple'>(" .. sgs.Sanguosha:translate(s[1].."-detail") .. ")</font>"
			end
		end
	end
	
	g2_property = g2_property .. "\n\n<b>成就奖励</b>："
	
	for i,a in pairs(tt) do
		local s = a:split("=")
		if not string.find(s[1], "_achievement") then
			g2_property = g2_property .. "\n" .. sgs.Sanguosha:translate(s[1]) .. ": "
			if s[2] == "0" then
				g2_property = g2_property .. "<font color='grey'>未解锁</font>"
			else
				g2_property = g2_property .. "<font color='red'>已解锁</font>" .. "<font color='purple'>(" .. sgs.Sanguosha:translate(s[1].."-detail") .. ")</font>"
			end
		end
	end
	
	sgs.LoadTranslationTable{
		["itemshow"] = "成就与奖励",
		["#itemshow"] = "彩蛋",
		["designer:itemshow"] = "技术提供:高达杀制作组",
		["cv:itemshow"] = "",
		["illustrator:itemshow"] = "",
		["itemnum"] = "成就与奖励",
		[":itemnum"] = g2_property,
		["$itemnum"] = "··成就达成音效··",
	}
end
