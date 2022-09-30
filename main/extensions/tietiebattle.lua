--[[
	太阳神三国杀游戏模式扩展包·联动大作战
	适用版本：V2 - 世界人权版（版本号：20131210）玉兔补丁（版本号：20131217）	--我管你适用什么版本，bug都给爷西内
	使用方法：
		将此扩展包放入游戏目录\extensions\文件夹中，重新启动太阳神三国杀，选择8人身份局模式。
		游戏开始选择武将后，会遇到是否进入“联动大作战”模式的询问，点击“确定”即可开启此游戏模式。
]]--
module("extensions.tietiebattle", package.seeall)
extension = sgs.Package("tietiebattle")
--技能暗将
HLModeSkillAnjiang = sgs.General(extension, "HLModeSkillAnjiang", "god", 5, true, true, true)
--翻译信息
sgs.LoadTranslationTable{
	["tietiebattle"] = "联动大作战",
	["04_tt_modename"] = "4 人局 [联动大作战]",
}


--[[****************************************************************
	游戏规则
]]--****************************************************************
--[[
	规则：位置固定
	内容：忠 - 反 - 忠 - 反 - 忠 - 反 - 忠 - 反
	内容：忠 - 反 - 反 - 忠
]]--

function TieTieAnimateString(player1, player2, player3, player4)
	local jpg_user = {}	--使用jpg的角色
	local suffix_player1 = "png"
	local suffix_player2 = "png"
	local suffix_player3 = "png"
	local suffix_player4 = "png"
	if table.contains(jpg_user, player1) then
		suffix_player1 = "jpg"
	end
	if table.contains(jpg_user, player2) then
		suffix_player2 = "jpg"
	end
	if table.contains(jpg_user, player3) then
		suffix_player3 = "jpg"
	end
	if table.contains(jpg_user, player4) then
		suffix_player4 = "jpg"
	end
	return "skill=TieTieStart:"..player1.."+"..player2.."+"..player3.."+"..player4..":"..suffix_player1.."+"..suffix_player2.."+"..suffix_player3.."+"..suffix_player4
end

function EnterHuangLvMode(room, current)
	--欢迎界面
	room:doLightbox("$WelcomeToHuangLvMode", 1500)	--显示全屏信息特效
	local msg = sgs.LogMessage()
	msg.type = "$AppendSeparator"
	room:sendLog(msg) --发送提示信息：分割线
	msg.type = "#HuangLvModeStart"
	room:sendLog(msg) --发送提示信息
	--确定四名玩家的位置
	local lord = room:getPlayers():first()
	local second = lord:getNextAlive()
	local third = second:getNextAlive()
	local forth = third:getNextAlive()
	local last = forth
	
	assert( last:getNextAlive():objectName() == lord:objectName() )
	
	--重置非主公角色的身份
	--[[lord:setRole("loyalist")
	second:setRole("rebel")
	third:setRole("rebel")
	forth:setRole("loyalist")
	
	room:setPlayerProperty(lord, "role", sgs.QVariant("loyalist"))
	room:changeHero(lord, lord:getGeneralName(), true, false, false, false)	--重置消除主公多出的体力上限，拥有的主公技效果等
	local start_hp = sgs.Sanguosha:getGeneral(lord:getGeneralName()):getStartHp()
	room:setPlayerProperty(lord, "hp", sgs.QVariant(start_hp))	--调整至起始血量（修正a/b型角色变身初始化后为满血）
	room:setPlayerProperty(second, "role", sgs.QVariant("rebel"))
	room:setPlayerProperty(third, "role", sgs.QVariant("rebel"))
	room:setPlayerProperty(forth, "role", sgs.QVariant("loyalist"))
	
	room:updateStateItem()
	--重置AI
	room:resetAI(lord)
	room:resetAI(second)
	room:resetAI(third)
	room:resetAI(forth)
	
	for i=1,4,1 do	--让ai容忍4次反身份操作
		sgs.updateIntention(second, lord, 200)	--AI跳反
		sgs.updateIntention(third, lord, 200)	--AI跳反
		sgs.updateIntention(forth, lord, -200)	--AI跳忠
	end]]
	
	--启用专有规则
	--local players = {lord, second, third, forth, fifth, sixth, seventh, eighth}
	local players = {lord, second, third, forth}
	room:acquireSkill(lord,"#HLModeBalance") --先手平衡规则
	room:acquireSkill(lord,"#HLModeBalanceRole") --先手平衡规则
	for _,p in ipairs(players) do
		--room:acquireSkill(p,"#HLModeTired") --疲劳回合规则，已改为全局技能
		--room:acquireSkill(p, "#HLModeRewardAndPunish") --击杀奖惩规则，已耦合进源码
		--room:acquireSkill(p, "#HLModeRewardAndPunishClear")
		--room:acquireSkill(p, "#HLModeVictory") --胜负判定规则，已耦合进源码
		room:attachSkillToPlayer(p, "HLyingyuan") --贴贴应援
		room:attachSkillToPlayer(p, "HLsurrender") --投降！
		--room:attachSkillToPlayer(p, "HLluli") --弱队勠力
	end
end
HLModeStart = sgs.CreateTriggerSkill{
	name = "#HLModeStart",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.BeforeGameStart, sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.MaxHpChanged, sgs.HpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BeforeGameStart then
			if room:getMode() == "04_tt" then	--4人局
				local tag = room:getTag("InHuangLvMode")
				if not tag:toBool() then
					--if player:getState() ~= "robot" then
						--if room:askForSkillInvoke(player, "HLModeStart") then
							room:setTag("InHuangLvMode", sgs.QVariant(true))
							EnterHuangLvMode(room, player)
							return false
						--end
					--end
				end
			end
		else
			--[[local tag = room:getTag("InHuangLvMode")
			if tag:toBool() then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:getRole() == "loyalist" or p:getRole() == "lord" then	--势力纠正
						if p:getKingdom() ~= "huang" then
							room:setPlayerProperty(p, "kingdom", sgs.QVariant("huang"))
						end
					elseif p:getRole() == "rebel" then
						if p:getKingdom() ~= "lv" then
							room:setPlayerProperty(p, "kingdom", sgs.QVariant("lv"))
						end
					end
				end
			end]]
		end
	end,
	priority = 10,
}
--添加规则
HLModeSkillAnjiang:addSkill(HLModeStart)
--翻译信息
sgs.LoadTranslationTable{
	["HLModeStart"] = "进入“联动大作战”模式",
	["$WelcomeToHuangLvMode"] = "联动大作战模式",
	["#HuangLvModeStart"] = "欢迎进入“联动大作战”模式",
}
--[[
	规则：先手平衡
	内容：先手玩家可以更换一次角色
	备注：原本应使用sgs.DrawInitialCards时机改变起始摸牌数，但启用此规则时该时机已过，
		所以改为sgs.DrawNCards时机改变第一次摸牌阶段摸牌数。
]]--
HLModeBalanceRole = sgs.CreateTriggerSkill{
	name = "#HLModeBalanceRole",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeGameStart},
	on_trigger = function(self, event, player, data)
		--if data:toPhaseChange().to ~= sgs.Player_NotActive then
			local room = player:getRoom()
			room:handleAcquireDetachSkills(player, "-"..self:objectName())
			
			local msg = sgs.LogMessage()
			msg.type = "#BalanceRoleRule"
			msg.from = player
			room:sendLog(msg) --发送提示信息
			
			local all = sgs.Sanguosha:getLimitedGeneralNames()
			for _,player in sgs.qlist(room:getAlivePlayers())do
				local name = player:getGeneralName()
				if sgs.Sanguosha:isGeneralHidden(name) then
					local fname = sgs.Sanguosha:findConvertFrom(name);
					if fname ~= "" then name = fname end
				end
				table.removeOne(all, name)
		
				if player:getGeneral2() == nil then continue end
		
				name = player:getGeneral2Name();
				if sgs.Sanguosha:isGeneralHidden(name) then
					local fname = sgs.Sanguosha:findConvertFrom(name);
					if fname ~= "" then name = fname end
				end
				table.removeOne(all, name)
			end
			
			local targets = room:getPlayers()
			local to_change = {}
			local general_names = {}
			local friend_seat = {4,3,2,1}	--每一位角色对应队友的位次
			
			local banned_list = {}	--获取电脑不能使用的角色
			local file = io.open("etc/banned.txt", "r")
			if file ~= nil then
				banned_list = file:read("*all"):split("\n")
				file:close()
			end
			
			for i = 1,4,1 do
				if #all == 0 then return end
				n = math.min(3, #all)
				local acquired = {}
				repeat
					local rand = math.random(1,#all)
					if not table.contains(acquired,all[rand]) and (targets:at(i-1):getState() ~= "robot" or not table.contains(banned_list,all[rand])) then
						table.insert(acquired,(all[rand]))
					end
				until #acquired == n
				
				room:setPlayerMark(targets:at(i-1), "Response_Time_Fix", 10000)	--读条时间固定10秒
				if targets:at(i-1):getState() ~= "robot" and room:askForSkillInvoke(targets:at(i-1), "#BalanceRoleRuleSkill", sgs.QVariant("change_self:"..i), false) then
					room:setPlayerMark(targets:at(i-1), "Response_Time_Fix", 0)
					local general_name = room:askForGeneral(targets:at(i-1), table.concat(acquired,"+"))
					
					if general_name then
						table.removeOne(all, general_name)
						table.insert(to_change, general_name)
					else
						table.insert(to_change, "")
					end
				elseif targets:at(i-1):getState() == "robot" and targets:at(friend_seat[i]-1):getState() ~= "robot" and room:askForSkillInvoke(targets:at(friend_seat[i]-1), "#BalanceRoleRuleSkill", sgs.QVariant("change_friend:"..i), false) then
					room:setPlayerMark(targets:at(i-1), "Response_Time_Fix", 0)
					local general_name = room:askForGeneral(targets:at(friend_seat[i]-1), table.concat(acquired,"+"))
					
					if general_name then
						table.removeOne(all, general_name)
						table.insert(to_change, general_name)
					else
						table.insert(to_change, "")
					end
				else
					table.insert(to_change, "")
				end
				room:setPlayerMark(targets:at(i-1), "Response_Time_Fix", 0)
			end
			
			for i = 1,4,1 do
				if to_change[i] ~= "" then
					local p = targets:at(i-1)
					
					if p:getTag("luajiantui_skill") then	--清除荐推的额外技能
						local jiantui_skill = p:getTag("luajiantui_skill"):toString()
						if jiantui_skill and jiantui_skill ~= "" then
							room:detachSkillFromPlayer(p, jiantui_skill)
						end
					end
					
					room:changeHero(p, "anjiang", true, false, false, false)
					for _,to in sgs.qlist(room:getAllPlayers()) do	--屏蔽所有角色的技能
						room:setPlayerMark(to, "skill_banned", 1)
					end
					p:setFlags("Fake_Move")
					room:setTag("FirstRound", sgs.QVariant(true))
					p:throwAllMarks(false)	--清除所有标记，true代表只清除可见标记（默认为true）
					p:clearPrivatePiles()	--清除所有私家牌
					p:clearFlags()	--清除所有flag
					p:throwAllCards()	--扔掉所有卡
					p:drawCards(4, self:objectName())
					p:setFlags("-Fake_Move")
					room:setTag("FirstRound", sgs.QVariant(false))
					for _,to in sgs.qlist(room:getAllPlayers()) do	--解除屏蔽所有角色的技能
						room:setPlayerMark(to, "skill_banned", 0)
					end
					room:changeHero(p, to_change[i], true, false, false, true)	--第四个参数调为false代表不触发游戏开始时类时机（因为换将流程在游戏开始前）
					local start_hp = sgs.Sanguosha:getGeneral(to_change[i]):getStartHp()
					room:setPlayerProperty(p, "hp", sgs.QVariant(start_hp))	--调整至起始血量（修正a/b型角色变身初始化后为满血）
				end
				table.insert(general_names, targets:at(i-1):getGeneralName())
			end
			room:swapPile(false)
			
			room:doAnimate(2, TieTieAnimateString(general_names[1], general_names[4], general_names[2], general_names[3]))	--播放动画
			room:getThread():delay(5000)
		--end
	end,
	priority = 6,
}
--添加规则
HLModeSkillAnjiang:addSkill(HLModeBalanceRole)
--翻译信息
sgs.LoadTranslationTable{
	["#BalanceRoleRule"] = "规则：所有玩家可以重置一次角色（三选一）",
	["#BalanceRoleRuleSkill"] = "更换角色",
	["#BalanceRoleRuleSkill:change_self"] = "你可以更换一次角色（三选一）",
	["#BalanceRoleRuleSkill:change_friend"] = "你可以为你的 %src 号位队友更换一次角色（三选一）",
}
--[[
	规则：先手平衡
	内容：先手玩家起始少摸一张牌
	备注：原本应使用sgs.DrawInitialCards时机改变起始摸牌数，但启用此规则时该时机已过，
		所以改为sgs.DrawNCards时机改变第一次摸牌阶段摸牌数。
]]--
HLModeBalance = sgs.CreateTriggerSkill{
	name = "#HLModeBalance",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		if player:getMark("HuangLvBalanceRule") == 0 then
			local room = player:getRoom()
			room:setPlayerMark(player, "HuangLvBalanceRule", 1)		
			local msg = sgs.LogMessage()
			msg.type = "#BalanceRule"
			msg.from = player
			room:sendLog(msg) --发送提示信息
			local n = data:toInt() - 1
			data:setValue(n)
			
		end
	end,
}
--添加规则
HLModeSkillAnjiang:addSkill(HLModeBalance)
--翻译信息
sgs.LoadTranslationTable{
	["#BalanceRule"] = "先手平衡规则：%from 第一次摸牌时将少摸一张牌",
}
--[[
	规则：疲劳回合规则
	内容：每名角色各自的第16个回合开始，回合结束时失去1点体力
	备注：翻面不计入回合
]]--
HLModeTired = sgs.CreateTriggerSkill{
	name = "#HLModeTired",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if room:getMode() ~= "04_tt" then return false end
		local change = data:toPhaseChange()
		if player:isAlive() and change.from ~= sgs.Player_NotActive and change.to == sgs.Player_NotActive then
			room:addPlayerMark(player, "@round", 1)
			if player:getMark("@round") >= 16 then
				local niepan_trigger = false
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("#characteristic_niepan") then
						room:sendCompulsoryTriggerLog(p, "#characteristic_niepan")
						niepan_trigger = true
					end
				end
				if niepan_trigger then
					local msg = sgs.LogMessage()
					msg.type = "#TiredRule"..math.random(1,45)
					msg.from = player
					room:sendLog(msg) --发送提示信息
					player:drawCards(2, self:objectName())
					room:damage(sgs.DamageStruct(self:objectName(), nil, player, 1, sgs.DamageStruct_Fire))
				else
					if not player:hasSkill("#characteristic_naijiu") then
						local msg = sgs.LogMessage()
						msg.type = "#TiredRule"..math.random(1,45)
						msg.from = player
						room:sendLog(msg) --发送提示信息
						room:loseHp(player)
					end
				end
			end
		end
	end,
	priority = -2,
}
--添加规则
HLModeSkillAnjiang:addSkill(HLModeTired)
--翻译信息
sgs.LoadTranslationTable{
	--["#TiredRule"] = "%from 进入了疲劳回合，持续失去体力",
	["#TiredRule1"] = "%from 感觉身体被掏空",
	["#TiredRule2"] = "%from 实在是太累了",
	["#TiredRule3"] = "%from 想睡觉了",
	["#TiredRule4"] = "%from 决定马上摸鱼",
	["#TiredRule5"] = "%from 遭到了 <font color=\"red\"><b>周瑜</b></font> 的鞭笞",
	["#TiredRule6"] = "%from 尝试锥刺股振作精神，好痛……",
	["#TiredRule7"] = "%from 尿意渐渐增强",
	["#TiredRule8"] = "%from 声带嘶哑",
	["#TiredRule9"] = "%from 的SAN值下降了 <font color=\"yellow\"><b>10</b></font> 点",
	["#TiredRule10"] = "年度最勤奋Vup：就是 %from ！",
	["#TiredRule11"] = "%from 已经很累了",
	["#TiredRule12"] = "突然，%from 觉得耐久联动挑战是个坏点子",
	["#TiredRule13"] = "直播中打瞌睡的话，%from 生涯就要结束了吧……",
	["#TiredRule14"] = "%from 想起了爷爷的话",
	["#TiredRule15"] = "%from 觉得审美疲劳了",
	["#TiredRule16"] = "%from 尝试喝咖啡振作，但腹泻了",
	["#TiredRule17"] = "%from ：“啊啊啊啊啊啊”",
	["#TiredRule18"] = "%from 仿佛看见了古神",
	["#TiredRule19"] = "%from 抽到SSR了！然而这只是一场梦",
	["#TiredRule20"] = "将将将，令人震惊的事实！%from 要坚持不下去啦！",
	["#TiredRule21"] = "%from 放弃了思考……",
	["#TiredRule22"] = "“我也是加把劲骑士”，%from 说",
	["#TiredRule23"] = "%from 试图使用证明数学定理",
	["#TiredRule24"] = "%from 对 <font color=\"red\"><b>桌子</b></font> 造成了 <font color=\"yellow\"><b>1</b></font> 点伤害",
	["#TiredRule25"] = "%from 开始降智了",
	["#TiredRule26"] = "%from 觉得力不从心",
	["#TiredRule27"] = "%from 一点问题都没有，但是由于游戏机制……",
	["#TiredRule28"] = "%from 疲于和DD对线",
	["#TiredRule29"] = "%from 的网络出现了问题",
	["#TiredRule30"] = "%from 尝试和自己贴贴",
	["#TiredRule31"] = "%from 运气真差！",
	["#TiredRule32"] = "检测到 %from 的高血压",
	["#TiredRule33"] = "%from 正在帮助开发人员写代码",
	["#TiredRule34"] = "%from 觉得体力值太多了",
	["#TiredRule35"] = "%from 的“<font color=\"yellow\"><b>崩坏</b></font>”被触发？大概……",
	["#TiredRule36"] = "乳 %from 的人实在是太多了",
	["#TiredRule37"] = "%from 想起开心的事情，但又想到自己还在耐久直播……",
	["#TiredRule38"] = "%from 的直播间被房管警告了",
	["#TiredRule39"] = "观众要求 %from 直播抽卡，%from 被迫榨干了最后一笔零用钱",
	["#TiredRule40"] = "%from 渐渐语无伦次",
	["#TiredRule41"] = "%from 大喊：“我不玩了！”",
	["#TiredRule42"] = "%from 惊讶地发现人被鲨就会死",
	["#TiredRule43"] = "%from 不禁“哈喽哦哦哦？？？”了起来，没人知道这是什么意思",
	["#TiredRule44"] = "%from 自称上千岁，并企图像乌龟一样缩壳休息",
	["#TiredRule45"] = "%from 不小心搞砸了工作",
}
--[[
	规则：击杀奖惩
	内容：1、击杀队友不会受到惩罚；
		2、击杀队友、敌人不会得到奖励；
		3、阵亡一方存活队友摸一张牌。
]]--
HLModeRewardAndPunish = sgs.CreateTriggerSkill{
	name = "#HLModeRewardAndPunish",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
		local friends = {}
		local alives = room:getAlivePlayers()
		local role = player:getRole()
		--主公阵亡找忠臣
		if role == "lord" then
			for _,p in sgs.qlist(alives) do
				if p:getRole() == "loyalist" then
					table.insert(friends, p)
				end
			end
		--忠臣阵亡找主公/忠臣
		elseif role == "loyalist" then
			for _,p in sgs.qlist(alives) do
				if p:getRole() == "lord" then
					table.insert(friends, p)
				elseif p:getRole() == "loyalist" then --这里考虑了“焚心”等改变身份的技能的影响
					table.insert(friends, p)
				end
			end
		--反贼阵亡找反贼
		elseif role == "rebel" then
			for _,p in sgs.qlist(alives) do
				if p:getRole() == "rebel" then
					table.insert(friends, p)
				end
			end
		end
		--存活的队友摸一张牌
		if #friends > 0 then
			for _,friend in ipairs(friends) do
				room:drawCards(friend, 1, "HLModeRewardAndPunish")
			end
		end
	end,
	can_trigger = function(self, target)
		return ( target ~= nil )
	end,
	priority = 2,
}
HLModeRewardAndPunishClear = sgs.CreateTriggerSkill{
	name = "#HLModeRewardAndPunishClear",
	frequency = sgs.Skill_Frequent,
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setTag("SkipNormalDeathProcess", sgs.QVariant(false))
	end,
	can_trigger = function(self, target)
		return ( target ~= nil )
	end,
	priority = -2,
}
extension:insertRelatedSkills("#HLModeRewardAndPunish", "#HLModeRewardAndPunishClear")
--添加规则
HLModeSkillAnjiang:addSkill(HLModeRewardAndPunish)
HLModeSkillAnjiang:addSkill(HLModeRewardAndPunishClear)
--翻译信息
sgs.LoadTranslationTable{
	["HLModeRewardAndPunish"] = "击杀奖惩",
	["tietie_draw:choice"] = "你的队友离场了，你想摸一张牌吗？",
}
--[[
	规则：胜负判定
	内容：1、主公阵亡，若有忠臣存活，则将忠臣升为主公
		2、主公阵亡，若无忠臣存活，则反贼胜利
		3、反贼阵亡，若无反贼存活，则主公和忠臣胜利
]]--
HLModeVictory = sgs.CreateTriggerSkill{
	name = "#HLModeVictory",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameOverJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setTag("SkipGameRule", sgs.QVariant(true))
		local alives = room:getAlivePlayers()
		local role = player:getRole()
		if role == "loyalist" then
			for _,p in sgs.qlist(alives) do
				if p:getRole() == "loyalist" then
					player:setRole("loyalist")
					room:setPlayerProperty(player, "role", sgs.QVariant("loyalist"))
					p:setRole("lord")
					room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
					return false
				end
			end
			room:gameOver("rebel")
		elseif role == "rebel" then
			for _,p in sgs.qlist(alives) do
				if p:getRole() == "rebel" then
					return false
				end
			end
			room:gameOver("loyalist+loyalist")
		end
	end,
	can_trigger = function(self, target)
		return ( target ~= nil )
	end,
	priority = 2,
}
--添加规则
HLModeSkillAnjiang:addSkill(HLModeVictory)

--公共技能

countFriends = function(player)
	local count = 0
	local players = player:getSiblings()
	for _,p in sgs.qlist(players) do
		if p:isAlive() then
			if p:getKingdom() == player:getKingdom() then
				count = count + 1
			end
		end
	end
	return count
end

countEnemies = function(player)
	local count = 0
	local players = player:getSiblings()
	for _,p in sgs.qlist(players) do
		if p:isAlive() then
			if p:getKingdom() ~= player:getKingdom() then
				count = count + 1
			end
		end
	end
	return count
end

getFriends = function(player)
	local friends = {}
	local alives = player:getSiblings()
	local role = player:getRole()
	if role == "lord" then
		for _,p in sgs.qlist(alives) do
			if p:getRole() == "loyalist" then
				table.insert(friends, p)
			end
		end
	elseif role == "loyalist" then
		for _,p in sgs.qlist(alives) do
			if p:getRole() == "lord" then
				table.insert(friends, p)
			elseif p:getRole() == "loyalist" then
				table.insert(friends, p)
			end
		end
	elseif role == "rebel" then
		for _,p in sgs.qlist(alives) do
			if p:getRole() == "rebel" then
				table.insert(friends, p)
			end
		end
	end
	return friend
end

isWeakTeam = function(player)
	if player then
		return countEnemies(player) > (countFriends(player) + 1)	--敌方人数多于我方人数（队友+自己）时我方为弱势方
	end
end

isStrongTeam = function(player)
	if player then
		return countEnemies(player) < (countFriends(player) + 1)	--敌方人数少于我方人数（队友+自己）时我方为强势方
	end
end

--[[
	技能：应援
	内容：强队角色可以把1张手牌交给其队友
	备注：强队定义为队伍人数多于敌队人数
	
	技能：新应援
	内容：出限一，可以把1张手牌交给队友
]]--
HLyingyuanCard = sgs.CreateSkillCard{
	name = "HLyingyuanCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if sgs.Self:getRole() == to_select:getRole() or (sgs.Self:getRole() == "lord" and to_select:getRole() == "loyalist") or (sgs.Self:getRole() == "loyalist" and to_select:getRole() == "lord") then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end ,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		--dest:obtainCard(self, false)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), dest:objectName(), "HLyingyuan", "")
		room:moveCardTo(self, dest, sgs.Player_PlaceHand, reason, true)
	end
}
HLyingyuan = sgs.CreateViewAsSkill{
	name = "HLyingyuan&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = HLyingyuanCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		local has_target = false
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if player:getRole() == p:getRole() or (player:getRole() == "lord" and p:getRole() == "loyalist") or (player:getRole() == "loyalist" and p:getRole() == "lord") then
				has_target = true
				break
			end
		end
		return has_target and not player:hasUsed("#HLyingyuanCard") --[[and isStrongTeam(player)]] and not player:isKongcheng()
	end
}

HLModeSkillAnjiang:addSkill(HLyingyuan)
sgs.LoadTranslationTable{
	["HLyingyuan"] = "应援",
	["hlyingyuan"] = "应援",
	--[":HLyingyuan"] = "阶段技，若你的队伍为强势队伍，你可以把一张手牌交给与你同队的其他角色",
	[":HLyingyuan"] = "出牌阶段限一次，你可以把一张手牌正面向上交给与你同队的其他角色。",
	["$HLyingyuan"] = "",
	["^HLyingyuan"] = "操作提示：选择一张手牌→选择一名队友（自动选择）→确定",
}

--------------------------------------------------
--投降
--------------------------------------------------

HLsurrenderCard = sgs.CreateSkillCard{
	name = "HLsurrenderCard",
	target_fixed = true,
	will_throw = false,
	filter = function(self, targets, to_select)
		return false
	end,
	on_use = function(self, room, source, targets)
		if source:hasSkill("#characteristic_neversurrender") then
			room:sendCompulsoryTriggerLog(source, "characteristic_neversurrender") --显示锁定技发动
			room:handleAcquireDetachSkills(source, "newjuejing|-HLsurrender")
		else
			room:setPlayerMark(source, "Response_Time_Fix", 5000)	--读条时间固定5秒
			if source:askForSkillInvoke("HLsurrender", sgs.QVariant("choice:")) then
				
				local log = sgs.LogMessage()
				log.from = source
				log.type = "#HLsurrender"
				room:sendLog(log)	--显示技能发动提示信息
				
				--room:setPlayerMark(source, "surrender", 1)	--配合源码显示断肠特效（特效再利用）
				
				--[[if source:getRole() == "loyalist" then
					room:gameOver("rebel")
				elseif source:getRole() == "rebel" then
					room:gameOver("loyalist")
				end]]
				--room:killPlayer(source)
				--room:loseMaxHp(source, source:getMaxHp())
				
				for _,to in sgs.qlist(room:getAllPlayers()) do	--屏蔽所有角色的技能
					room:setPlayerMark(to, "skill_banned", 1)
				end
				room:loseHp(source, source:getHp()+5834)
			else
				local log = sgs.LogMessage()
				log.from = source
				log.type = "#HLsurrenderNo"
				room:sendLog(log)	--显示技能发动提示信息
			end
			room:setPlayerMark(source, "Response_Time_Fix", 0)
		end
	end
}
HLsurrender = sgs.CreateZeroCardViewAsSkill{
	name = "HLsurrender&",
	view_as = function()
		return HLsurrenderCard:clone()
	end,
	enabled_at_play = function(self, player)
		local has_target = false
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if player:getRole() == p:getRole() or (player:getRole() == "lord" and p:getRole() == "loyalist") or (player:getRole() == "loyalist" and p:getRole() == "lord") then
				has_target = true
				break
			end
		end
		return not has_target and not player:hasUsed("#HLsurrenderCard")
	end
}

HLModeSkillAnjiang:addSkill(HLsurrender)

sgs.LoadTranslationTable{
	["HLsurrender"] = "投降",
	["hlsurrender"] = "准备投降",
	["HLsurrender>>"] = "surrender",	--技能按钮上的角色小图标
	[":HLsurrender"] = "出牌阶段限一次，若你没有存活队友，你可以投降。",
	["$HLsurrender"] = "",
	["HLsurrender:choice"] = "你真的要投降吗？",
	["#HLsurrender"] = "%from 投降了",
	["#HLsurrenderNo"] = "%from 取消投降",
}

--[[
	技能：勠力
	内容：弱队角色成为【杀】或【黄绿对决】的目标时可以摸X弃Y，X为本队伍阵亡人数，Y为敌队阵亡人数
	备注：弱队定义为队伍人数少于敌队人数
]]--
HLluli = sgs.CreateTriggerSkill{
	name = "HLluli",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if (use.card:isKindOf("Slash") or use.card:isKindOf("Duijue")) and use.to:contains(player) then
			if isWeakTeam(player) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:sendCompulsoryTriggerLog(player, self:objectName()) --显示锁定技发动
					player:drawCards(3-countFriends(player))
					if 4-countEnemies(player) > 0 then
						room:askForDiscard(player, self:objectName(), (4-countEnemies(player)), (4-countEnemies(player)), false, true)
					end
				end
			end
		end
	end,
	priority = 1,
}
--添加规则
HLModeSkillAnjiang:addSkill(HLluli)
--翻译信息
sgs.LoadTranslationTable{
	["HLluli"] = "勠力",
	["hlluli"] = "勠力",
	[":HLluli"] = "你成为【杀】或【黄绿对决】的目标时，若你的队伍为弱势队伍，你可以摸X张牌弃Y张牌(X为已阵亡队友数，Y为已阵亡敌人数)",
	["$HLluli"] = "",
}

--联动大作战模式新卡牌
--[[****************************************************************
	系统控制
]]--****************************************************************
local generals = sgs.Sanguosha:getLimitedGeneralNames()
for _,name in ipairs(generals) do
	local general = sgs.Sanguosha:getGeneral(name)
	if general and not general:isTotallyHidden() then
		general:addSkill("#HLModeStart")
	end
end