--[[
	冰火歌会
]]--
module("extensions.icefire", package.seeall)
extension = sgs.Package("icefire")
--技能暗将
IFModeSkillAnjiang = sgs.General(extension, "IFModeSkillAnjiang", "god", 5, true, true, true)
--翻译信息
sgs.LoadTranslationTable{
	["icefire"] = "冰火歌会",
	["04_if_modename"] = "4 人局 [冰火歌会 四回战]",
	["ice_leader"] = "冰队队长",
	["fire_leader"] = "火队队长",
	["if_iget_1"] = "田汐汐+冰队选择一名队员",
	["if_iget_2"] = "田汐汐+冰队选择两名队员",
	["if_fget_2"] = "小虾鱼+火队选择两名队员",
	["if_iselect_1"] = "田汐汐+冰队选择首发队员",
	["if_iselect_2"] = "田汐汐+冰队选择两名待命队员",
	["if_fselect_1"] = "小虾鱼+火队选择首发队员",
	["if_fselect_2"] = "小虾鱼+火队选择两名待命队员",
}

--------------------------------------------------
--小虾鱼
--设计者：
--------------------------------------------------

xiaoxiayu_leader = sgs.General(extension,"xiaoxiayu_leader","team_fire","8",false,true,true)

sgs.LoadTranslationTable{
	["xiaoxiayu_leader"] = "小虾鱼",
	["&xiaoxiayu_leader"] = "小虾鱼",
	["#xiaoxiayu_leader"] = "灼热疾风",
	["$xiaoxiayu_leader"] = "",
	["designer:xiaoxiayu_leader"] = "",
	["cv:xiaoxiayu_leader"] = "",
	["illustrator:xiaoxiayu_leader"] = "",
	["~xiaoxiayu_leader"] = "",
}

--------------------------------------------------
--田汐汐
--设计者：
--------------------------------------------------

tianxixi_leader = sgs.General(extension,"tianxixi_leader","team_ice","8",false,true,true)

sgs.LoadTranslationTable{
	["tianxixi_leader"] = "田汐汐",
	["&tianxixi_leader"] = "田汐汐",
	["#tianxixi_leader"] = "冰雪奇迹",
	["$tianxixi_leader"] = "",
	["designer:tianxixi_leader"] = "",
	["cv:tianxixi_leader"] = "",
	["illustrator:tianxixi_leader"] = "",
	["~tianxixi_leader"] = "",
}


--------------------------------------------------
--函数部分
--------------------------------------------------

--获取队友
function getFriend(player)
	for _, p in sgs.qlist(player:getSiblings()) do
		if player:isYourFriend(p, "04_if") then
			return p
		end
	end
	return nil
end


--获取存活队友
function getAliveFriend(player)
	for _, p in sgs.qlist(player:getAliveSiblings()) do
		if player:isYourFriend(p, "04_if") then
			return p
		end
	end
	return nil
end


--自己是否为队长
function isTeamLeader(player)
	if player:getRole() == "lord" or player:getRole() == "renegade" then
		return true
	end
	return false
end


--获取所在队队长，需要room（第二个参数为真则获取对方队长，第三个参数为真则包含离场角色）
function findTeamLeader(player, find_enemy, include_dead)
	local room = player:getRoom()
	local range = room:getAllPlayers()
	if include_dead then
		range = room:getAllPlayers(true)
	end
	for _, p in sgs.qlist(range) do
		if isTeamLeader(p) and ((not find_enemy and player:isYourFriend(p, "04_if")) or (find_enemy and not player:isYourFriend(p, "04_if"))) then
			return p
		end
	end
	return nil
end


--获取所在队队员（同上）
function findTeamMember(player, find_enemy, include_dead)
	local room = player:getRoom()
	local range = room:getAllPlayers()
	if include_dead then
		range = room:getAllPlayers(true)
	end
	for _, p in sgs.qlist(range) do
		if not isTeamLeader(p) and ((not find_enemy and player:isYourFriend(p, "04_if")) or (find_enemy and not player:isYourFriend(p, "04_if"))) then
			return p
		end
	end
	return nil
end

--Player類型轉至ServerPlayer
function player2splayer(room, player)
	local room = player:getRoom()
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if move.from and p:objectName() == player:objectName() then
			return p
		end
	end
end

--记录玩家可解锁的角色
--可解锁的角色记录在玩家的"UnlockGeneralNames"tag内，格式为字符串table
--在zzsystem.lua中处理，与胜率计算同时进行

function RecordUnlockGenerals(player, general_name)
	local general = sgs.Sanguosha:getGeneral(general_name)
	if general and general:isBonus() then
		player:getRoom():setPlayerMark(player, "unlock_"..general_name.."-Keep", 1)		--结尾为-Keep的标记不会在角色死亡时被清除
	end
end

--[[
	规则：征服规则
	内容：队长的回合结束时，若其没有在场队友，则失去1点体力
	备注：
]]--
IFModeNoFriend = sgs.CreateTriggerSkill{
	name = "#IFModeNoFriend",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if room:getMode() ~= "04_if" then return false end
		local change = data:toPhaseChange()
		if player:isAlive() and change.from ~= sgs.Player_NotActive and change.to == sgs.Player_NotActive then
			if isTeamLeader(player) and getAliveFriend(player) == nil then
				local msg = sgs.LogMessage()
				msg.type = "#IF_NoFriend_Rule"
				msg.from = player
				room:sendLog(msg) --发送提示信息
				room:loseHp(player)
			end
		end
	end,
	priority = -2,
}
--添加规则
IFModeSkillAnjiang:addSkill(IFModeNoFriend)
--翻译信息
sgs.LoadTranslationTable{
	["#IF_NoFriend_Rule"] = "%from 没有队友的支持，将持续失去体力",
}



--[[
	规则：应援力系统
	内容：
		1.每轮开始时，双方玩家各获得1应援力（第一轮仅冰队玩家获得），应援力已满的玩家改为摸一张牌。
		2.玩家对敌方玩家造成伤害后，获得1应援力，若为冰霜或火焰属性伤害则额外获得1应援力。
		3.回合开始时，玩家可以消耗2应援力选择一个随机技能获得（三选一），可以花费1应援力刷新，可以花费1应援力改为让队长获得技能。
		4.每名角色至多持有4个技能（包括该角色本身的技能），技能数超过4个后，需由本队的玩家选择技能失去直到技能数为4。
	备注：
		1.应援力上限为5
		2.玩家的当前角色离场时，失去所有应援力和通过应援力获得的技能
]]--

local cheer_marks = {"@Cheer_1","@Cheer_2","@Cheer_3","@Cheer_4","@Cheer_5","@Cheer_6","@Cheer_7","@Cheer_8"}
local max_cheer = 5

function countCheer(player)
	local count = 0
	for _, cheer_mark in ipairs(cheer_marks) do
		if player:getMark(cheer_mark) > 0 then
			count = count + 1
		end
	end
	return count
end

function gainCheer(player, count)
	count = count or 1
	for i=1,count,1 do
		if countCheer(player) < max_cheer then
			local cheers = {}
			for _, cheer_mark in ipairs(cheer_marks) do
				if player:getMark(cheer_mark) == 0 then
					table.insert(cheers, cheer_mark)
				end
			end
			player:gainMark(cheers[math.random(1,#cheers)], 1)
		else
			break
		end
	end
end

function loseCheer(player, count)
	count = count or 1
	for i=1,count,1 do
		if countCheer(player) > 0 then
			local cheers = {}
			for _, cheer_mark in ipairs(cheer_marks) do
				if player:getMark(cheer_mark) > 0 then
					table.insert(cheers, cheer_mark)
				end
			end
			player:loseMark(cheers[math.random(1,#cheers)], 1)
		else
			break
		end
	end
end

--禁止获得的技能，包括：部分非即时的遗言技能、涉及变身的技能、涉及给其他角色技能按钮的技能（如月引、秘恋，因为换角色会掉）、部分特例
local IFModeCheerSystem_banned_list = {"luajiantui", "luajiyuan", "luashenhui", "youlian", "yanling", "heli", "qiji", "milian", "yuguang", "yueyin", "milian", "shisu", "xingji"}
local luaIFModeCheerSystem_extra_generals_list = {"bingtang_if", "hanazono_serena_if", "xiaorou_if", "xiachuanyueyue_if", "baishenyao_if", "xingxi_if", "otome_oto_if", "katya_if", "takatsuki_ritsu", "chigusa_hana"}	--额外加入技能池的角色
local luaIFModeCheerSystem_throw_generals_list = {"baishenyao_zhaijiahaibao", "xingxi_tianjiliuxing", "xiachuanyueyue_duzhuoguitu", "xiaorou_rhoxingai", "tisi_sishenshejishi"}	--从技能池中排除的角色

IFModeCheerSystem = sgs.CreateTriggerSkill{
	name = "IFModeCheerSystem",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.RoundStart, sgs.Damage, sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.MarkChanged},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if room:getMode() ~= "04_if" then return false end
		if not player or not player:isAlive() then return false end
		
		if event == sgs.RoundStart then
			if room:getTag("TurnLengthCount"):toInt() > 1 then
				if not isTeamLeader(player) then
					if countCheer(player) < max_cheer then
						gainCheer(player, 1)
					else
						player:drawCards(1)
					end
				end
			elseif room:getTag("TurnLengthCount"):toInt() == 1 then
				if player:getRole() == "rebel" then
					if countCheer(player) < max_cheer then
						gainCheer(player, 1)
					else
						player:drawCards(1)
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.damage > 0 and not isTeamLeader(player) and damage.to and damage.to:objectName() ~= player:objectName() and not isTeamLeader(damage.to) then
				gainCheer(player, 1)
				if damage.nature == sgs.DamageStruct_Fire or damage.nature == sgs.DamageStruct_Ice then
					gainCheer(player, 1)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_NotActive and change.to ~= sgs.Player_NotActive and not isTeamLeader(player) and countCheer(player) >= 2 and room:askForSkillInvoke(player, "IFModeCheerSystem", sgs.QVariant("choice:")) then
				loseCheer(player, 2)
				
				local generals = sgs.Sanguosha:getLimitedGeneralNames()
				
				for _, general_name in ipairs(luaIFModeCheerSystem_extra_generals_list) do	--加入这些额外角色
					if not table.contains(generals, general_name) then
						table.insert(generals, general_name)
					end
				end
				
				for _, general_name in ipairs(luaIFModeCheerSystem_throw_generals_list) do	--排除这些角色
					if table.contains(generals, general_name) then
						table.removeOne(generals, general_name)
					end
				end
				
				local banned_list = {}	--获取电脑不能使用的角色
				local file = io.open("etc/banned.txt", "r")
				if file ~= nil then
					banned_list = file:read("*all"):split("\n")
					file:close()
				end
				for _, general_name in ipairs(banned_list) do	--排除电脑不能使用的角色
					if table.contains(generals, general_name) then
						table.removeOne(generals, general_name)
					end
				end
				
				for _, p in sgs.qlist(room:getAllPlayers(false)) do		--角色池排除出场角色
					table.removeOne(generals, p:getGeneralName())
					if not isTeamLeader(p) then		--包括（未出场的）备战角色
						for _, general_name in ipairs(p:getSelected()) do
							table.removeOne(generals, general_name)
						end
					end
				end
				
				local canget_skills = {}
				for _, general_name in ipairs(generals) do
					local general = sgs.Sanguosha:getGeneral(general_name)
					if not general then continue end	--防止添加了不存在的角色（如删人）
					local skills = general:getSkillList()	--General::getSkillList()无参数，后面使用isVisible确定技能不是隐藏技能
					for _, skill in sgs.qlist(skills) do
						if skill:isVisible() and skill:getFrequency() ~= sgs.Skill_Wake and not skill:isLordSkill() and not table.contains(IFModeCheerSystem_banned_list, skill:objectName()) then
							if not player:hasSkill(skill:objectName()) then
								local repeated = false
								for _, name in ipairs(canget_skills) do
									if skill:objectName() == name then
										repeated = true
										break
									end
								end
								if not repeated then
									table.insert(canget_skills, skill:objectName())
								end
							end
						end
					end
				end
				
				for _, p in sgs.qlist(room:getAlivePlayers()) do		--技能池排除存活角色拥有的技能
					for _, skill in sgs.qlist(p:getSkillList(false, true)) do
						table.removeOne(canget_skills, skill:objectName())
					end
				end
				
				::IFModeCheerSystem_refresh_point::
				local choices = {}
				local X = 3
				--[[if player:getMark("@luajiyuan_add") > 0 then
					room:setPlayerMark(player, "@luajiyuan_add", 0)
					X = 5
				end]]
				while #choices < X and #canget_skills > 0 do
					local random_one = math.random(1, #canget_skills)
					table.insert(choices, canget_skills[random_one])
					table.removeOne(canget_skills, canget_skills[random_one])
				end
				local minus = 0
				if countCheer(player) > 0 then
					table.insert(choices, "cancel_refresh")
					minus = 1
				end
				--table.insert(choices, "shuoyi")	--测试用
				local choice = room:askForChoice(player, self:objectName().."+".."IFModeCheerSystem_choice_log1".."+"..tostring(#choices - minus).."+".."IFModeCheerSystem_choice_log2", table.concat(choices, "+"))
				if choice and choice ~= "" then
					if choice == "cancel_refresh" then
						loseCheer(player, 1)
						goto IFModeCheerSystem_refresh_point
					end
					if countCheer(player) > 0 and room:askForSkillInvoke(player, "IFModeCheerSystem", sgs.QVariant("choice2:")) then
						loseCheer(player, 1)
						local leader = findTeamLeader(player, false)
						room:doAnimate(1, player:objectName(), leader:objectName())	--doAnimate 1:产生一条从前者到后者的指示线
						room:acquireSkill(leader, choice)
					else
						room:acquireSkill(player, choice)
					end
					
					local skill = sgs.Sanguosha:getSkill(choice)
					if skill and skill:isChangeSkill() then
						RecordUnlockGenerals(player, "limusi_v2")
					end
				end
			end
		elseif event == sgs.EventAcquireSkill then
			::IFModeDetachSkill::
			local skill_names = {}
			for _, skill in sgs.qlist(player:getSkillList(false, true)) do
				if not skill:isAttachedLordSkill() and not skill:isLordSkill() and not string.startsWith(sgs.Sanguosha:translate(":"..skill:objectName()), "<font color='#008B8B'><b>衍生技，</b></font>") then
					table.insert(skill_names, skill:objectName())
				end
			end
			if #skill_names > 4 then
				local choice = room:askForChoice(findTeamMember(player), self:objectName().."+".."IFModeCheerSystem_choice_log3", table.concat(skill_names, "+"))
				if choice and choice ~= "" then
					room:detachSkillFromPlayer(player, choice)
				end
				
				goto IFModeDetachSkill
			end
		elseif event == sgs.MarkChanged then	--通过添加标记来操控应援力的增减，用于其他文件中的技能
			if data:toMark().name == "IF_gaincheer" then
				for i=1,player:getMark("IF_gaincheer"),1 do
					gainCheer(player, 1)
				end
				room:setPlayerMark(player, "IF_gaincheer", 0)
			elseif data:toMark().name == "IF_losecheer" then
				for i=1,player:getMark("IF_losecheer"),1 do
					loseCheer(player, 1)
				end
				room:setPlayerMark(player, "IF_losecheer", 0)
			end
		end
	end,
	priority = -2,
}
--添加规则
IFModeSkillAnjiang:addSkill(IFModeCheerSystem)
--翻译信息
sgs.LoadTranslationTable{
	["IFModeCheerSystem"] = "冰火歌会",
	["IFModeCheerSystem:choice"] = "你可以消耗 2 应援力，从随机三个技能中选择一个获得",
	["IFModeCheerSystem:choice2"] = "你可以消耗 1 应援力，令队长获得所选技能",
	["IFModeCheerSystem_choice_log1"] = "请从以下",
	["IFModeCheerSystem_choice_log2"] = "个技能中选择一个\n花费1应援力可刷新列表\n鼠标悬停可查看技能描述",
	["IFModeCheerSystem_choice_log3"] = "请从以下技能中移除一个技能\n鼠标悬停可查看技能描述",
	["@Cheer_1"] = "应援力",
	["@Cheer_2"] = "应援力",
	["@Cheer_3"] = "应援力",
	["@Cheer_4"] = "应援力",
	["@Cheer_5"] = "应援力",
	["@Cheer_6"] = "应援力",
	["@Cheer_7"] = "应援力",
	["@Cheer_8"] = "应援力",
}

--[[
	规则：接力规则
	内容：玩家可以主动离场，然后获得2应援力
	备注：
]]--

IFRelayCard = sgs.CreateSkillCard{
	name = "IFRelayCard",
	target_fixed = true,
	will_throw = false,
	filter = function(self, targets, to_select)
		return false
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "Response_Time_Fix", 5000)	--读条时间固定5秒
		if source:askForSkillInvoke("IFRelay", sgs.QVariant("choice:")) then
			room:setPlayerMark(source, "Response_Time_Fix", 0)
			
			local log = sgs.LogMessage()
			log.from = source
			log.type = "#IFRelay"
			room:sendLog(log)	--显示技能发动提示信息
			
			room:killPlayer(source)
			
			if source:isAlive() then
				--room:attachSkillToPlayer(source, "IFRelay")
				gainCheer(source, 2)
			end
		else
			local log = sgs.LogMessage()
			log.from = source
			log.type = "#IFRelayNo"
			room:sendLog(log)	--显示技能发动提示信息
		end
		room:setPlayerMark(source, "Response_Time_Fix", 0)
	end
}
IFRelay = sgs.CreateZeroCardViewAsSkill{
	name = "IFRelay&",
	view_as = function()
		return IFRelayCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#IFRelayCard")
	end
}

IFModeSkillAnjiang:addSkill(IFRelay)


IFModeRelayInitial = sgs.CreateTriggerSkill{
	name = "#IFModeRelayInitial",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.BuryVictim},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if room:getMode() ~= "04_if" then return false end
		if event == sgs.GameStart then
			room:attachSkillToPlayer(player, "IFRelay")
		elseif event == sgs.BuryVictim then	--离场后重新获得此技能
			room:attachSkillToPlayer(player, "IFRelay")
		end
	end,
	priority = -2,
}
--添加规则
IFModeSkillAnjiang:addSkill(IFModeRelayInitial)
--翻译信息
sgs.LoadTranslationTable{
	["IFRelay"] = "接力",
	["ifrelay"] = "准备接力",
	[":IFRelay"] = "出牌阶段限一次，你可以离场，然后获得2应援力。",
	["$IFRelay"] = "",
	["IFRelay:choice"] = "你真的要接力吗？",
	["#IFRelay"] = "%from 决定接力",
	["#IFRelayNo"] = "%from 取消接力",
}

