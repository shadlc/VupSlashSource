
local cheer_marks = {"@Cheer_1","@Cheer_2","@Cheer_3","@Cheer_4","@Cheer_5","@Cheer_6","@Cheer_7","@Cheer_8"}

function countCheer(player)
	local count = 0
	for _, cheer_mark in ipairs(cheer_marks) do
		if player:getMark(cheer_mark) > 0 then
			count = count + 1
		end
	end
	return count
end


function SmartAI:canAttack(enemy, attacker, nature)
	attacker = attacker or self.player
	nature = nature or sgs.DamageStruct_Normal
	local damage = 1
	if nature == sgs.DamageStruct_Fire and not enemy:hasArmorEffect("silver_lion") then
		if enemy:hasArmorEffect("vine") then damage = damage + 1 end
		if enemy:getMark("@gale") > 0 then damage = damage + 1 end
		if enemy:hasSkill("ranshang") then damage = damage + 1 end
	elseif nature == sgs.DamageStruct_Thunder and not enemy:hasArmorEffect("silver_lion") then
		if enemy:hasArmorEffect("toujing") then damage = damage + 1 end
	end
	if #self.enemies == 1 or self:hasSkills("jueqing") then return true end
	if self:getDamagedEffects(enemy, attacker) or (self:needToLoseHp(enemy, attacker, false, true) and #self.enemies > 1) or not sgs.isGoodTarget(enemy, self.enemies, self) then return false end
	if self:objectiveLevel(enemy) <= 2 or self:cantbeHurt(enemy, self.player, damage) or not self:damageIsEffective(enemy, nature, attacker) then return false end
	if nature ~= sgs.DamageStruct_Normal and nature ~= sgs.DamageStruct_Light and enemy:isChained() and not self:isGoodChainTarget(enemy, self.player, nature) then return false end
	return true
end

function hasExplicitRebel(room)
	room = room or global_room
	for _, player in sgs.qlist(room:getAllPlayers()) do
		if sgs.isRolePredictable() and  sgs.evaluatePlayerRole(player) == "rebel" then return true end
		if sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then return true end
	end
	return false
end

function sgs.isGoodHp(player)
	local goodHp = player:getHp() > 1 or getCardsNum("Peach", player) >= 1 or getCardsNum("Analeptic", player) >= 1
					or hasBuquEffect(player)
					or (player:hasSkill("niepan") and player:getMark("@nirvana") > 0)
					or (player:hasSkill("shengguangN") and player:getMark("@halo") > 0)
					or (player:hasSkill("shisu") and player:getMark("@shisu") > 0)
					or (player:hasSkill("fuli") and player:getMark("@laoji") > 0)
	if goodHp then
		return goodHp
	else
		for _, p in sgs.qlist(global_room:getOtherPlayers(player)) do
			if sgs.compareRoleEvaluation(p,"rebel","loyalist")==sgs.compareRoleEvaluation(player,"rebel","loyalist")
					and getCardsNum("Peach",p)>0 and not global_room:getCurrent():hasSkill("wansha") then
				return true
			end
		end
		return false
	end
end

function sgs.isGoodTarget(player, targets, self, isSlash)
	local arr = {"jieming", "yiji", "guixin", "fangzhu", "neoganglie", "nosmiji", "xuehen", "xueji", "jiexin", "yishou", "yuechao", "chuangshi"}
	local m_skill = false
	local attacker = global_room:getCurrent()

	if targets and type(targets)=="table" then
		if #targets == 1 then return true end
		local foundtarget = false
		for i = 1, #targets, 1 do
			if sgs.isGoodTarget(targets[i]) and not self:cantbeHurt(targets[i]) then
				foundtarget = true
				break
			end
		end
		if not foundtarget then return true end
	end

	for _, masochism in ipairs(arr) do
		if player:hasSkill(masochism) then
			if masochism == "nosmiji" and player:isWounded() then m_skill = false
			elseif masochism == "xueji" and player:isWounded() then m_skill = false
			elseif attacker and attacker:hasSkill("jueqing") then m_skill = false
			elseif masochism == "jieming" and self and self:getJiemingChaofeng(player) > -4 then m_skill = false
			elseif masochism == "yiji" and self and not self:findFriendsByType(sgs.Friend_Draw, player) then m_skill = false
			elseif masochism == "jiexin" and self and not self:findFriendsByType(sgs.Friend_Draw, player) then m_skill = false
			elseif masochism == "chuangshi" and self and not self:findFriendsByType(sgs.Friend_Draw, player) then m_skill = false
			elseif masochism == "yishou" and self and not self:willSkipDrawPhase(player) and not self:willSkipPlayPhase(player) then m_skill = false
			elseif masochism == "yuechao" and player:getMark("yuechao_used") > 0 then m_skill = false
			else
				m_skill = true
				break
			end
		end
	end

	if not (attacker and attacker:hasSkill("jueqing")) and player:hasSkill("huilei") and not player:isLord() and player:getHp() == 1 then
		if attacker and attacker:getHandcardNum() >= 4 then return false end
		return sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel"
	end

	if not (attacker and attacker:hasSkill("jueqing")) and player:hasSkill("wuhun") and not player:isLord()
		and ((attacker and attacker:isLord()) or player:getHp() <= 2) then
		return false
	end

	if player:hasSkill("wangxiang") and player:getMark("@constellation") > 0 and player:getMark("wangxiang_hp") > 0 then		--望乡，一刀一刀刮
		if player:getHp() < player:getMark("wangxiang_hp") then
			return false
		end
	end
	
	if not (attacker and attacker:hasSkills("jueqing|xingyao")) and player:hasSkill("yuguang") and not player:isLord()
		and ((attacker and attacker:isLord()) or player:getHp() == 1) then
		return false
	end

	if player:hasLordSkill("shichou") and player:getMark("@hate") == 0 then
		for _, p in sgs.qlist(player:getRoom():getOtherPlayers(player)) do
			if p:getMark("hate_" .. player:objectName()) > 0 and p:getMark("@hate_to") > 0 then
				return false
			end
		end
	end

	if isSlash and self and (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0) and self:getCardsNum("Slash") > player:getHp() then
		return true
	end

	if player:hasSkill("hunzi") and player:getMark("hunzi") == 0 and player:isLord() and player:getHp() >= 2 and sgs.current_mode_players["loyalist"] > 0 then
		return false
	end
	
	if player:hasSkills("tuifeng|yishou") and player:getHandcardNum() > 2 and player:getHp() >= 2 then
		return false
	end

	if m_skill and sgs.isGoodHp(player) then
		return false
	else
		return true
	end
end

function sgs.getDefenseSlash(player, self)
	if not player then return 0 end
	local attacker = self and self.player or global_room:getCurrent()
	local defense = getCardsNum("Jink", player, attacker)

	local knownJink = getKnownCard(player, attacker, "Jink", true)

	if sgs.card_lack[player:objectName()]["Jink"] == 1 and knownJink == 0 then defense = 0 end

	defense = defense + knownJink * 1.2

	local hasEightDiagram = false

	if (player:hasArmorEffect("eight_diagram") or (player:hasSkills("bazhen|linglong|xiangrui") and not player:getArmor()))
	  and not IgnoreArmor(attacker, player) then
		hasEightDiagram = true
	end

	if hasEightDiagram then
		defense = defense + 1.3
		if player:hasSkills("tiandu|xiangrui") then defense = defense + 0.6 end
		if player:hasSkill("gushou") then defense = defense + 0.4 end
		if player:hasSkills("leiji") then defense = defense + 0.4 end
		if player:hasSkills("nosleiji") then defense = defense + 0.4 end
		if player:hasSkills("olleiji") then defense = defense + 0.4 end
		if player:hasSkills("xiaoan") then defense = defense + 0.4 end
		if player:hasSkill("noszhenlie") then defense = defense + 0.2 end
		if player:hasSkill("hongyan") then defense = defense + 0.2 end
	end

	if getCardsNum("Jink", player, global_room:getCurrent()) >= 1 then
		if player:hasSkill("mingzhe") then defense = defense + 0.2 end
		if player:hasSkill("gushou") then defense = defense + 0.2 end
		if player:hasSkills("tuntian+zaoxian") then defense = defense + 1.5 end
	end

	if player:hasSkill("aocai") and player:getPhase() == sgs.Player_NotActive then defense = defense + 0.5 end
	if player:hasSkill("wanrong") and not hasManjuanEffect(player) then defense = defense + 0.5 end
	
	--周泰不屈防禦
	if player:hasSkill("buqu") then defense = defense + 13 - player:getPile("trauma"):length() end
	--第二版神趙雲防禦
	if player:hasSkills("new_longhun+new_juejing") then defense = defense + 3 end
	--秦宓專對天辯防禦
	--現在先注解掉，因為這行會造成AI打秦宓隊友但秦宓諫征造成殺浪費
	--if player:hasSkills("zhuandui+tianbian") and not player:isKongcheng() then defense = defense + 2 end
	--曹節守璽防禦
	local shouxi_mark_count = 0
	for _, mark in sgs.list(player:getMarkNames()) do
		if string.find(mark, "shouxi") and player:getMark(mark) > 0 then
			shouxi_mark_count = shouxi_mark_count + 1
		end
	end
	if player:hasSkill("shouxi") then defense = defense + 13 - shouxi_mark_count end
	--諸葛瞻-第二版父蔭防禦
	if player:hasSkill("fuyin_sec_rev") and attacker:getHandcardNum() > player:getHandcardNum() and player:getMark("fuyin_sec_rev-Clear") == 0 then defense = defense + 10 end
	--有橘標記防禦
	if player:getMark("@orange") > 0 then defense = defense + 1.5 end
	--嵇康清弦防禦
	if player:hasSkill("qingxian") then defense = defense + 2 + player:getHp() end
	--下家防禦
	if global_room:getCurrent():objectName() == attacker:objectName() and attacker:getNextAlive():objectName() == player:objectName() then
		defense = defense - 0.4
	end

	local hujiaJink = 0
	if player:hasLordSkill("hujia") then
		local lieges = global_room:getLieges("wei", player)
		for _, liege in sgs.qlist(lieges) do
			if sgs.compareRoleEvaluation(liege,"rebel","loyalist") == sgs.compareRoleEvaluation(player,"rebel","loyalist") then
				hujiaJink = hujiaJink + getCardsNum("Jink", liege, global_room:getCurrent())
				if liege:hasArmorEffect("eight_diagram") then hujiaJink = hujiaJink + 0.8 end
			end
		end
		defense = defense + hujiaJink
	end

	if player:getMark("@tied") > 0 and not attacker:hasSkill("jueqing") then defense = defense + 1 end

	if attacker:canSlashWithoutCrossbow() and attacker:getPhase() == sgs.Player_Play then
		local hcard = player:getHandcardNum()
		if attacker:hasSkill("liegong") and (hcard >= attacker:getHp() or hcard <= attacker:getAttackRange()) then defense = 0 end
		if attacker:hasSkill("kofliegong") and hcard >= attacker:getHp() then defense = 0 end
	end

	local jiangqin = global_room:findPlayerBySkillName("niaoxiang")
	local need_double_jink = attacker:hasSkills("wushuang|drwushuang")
							or (attacker:hasSkill("luafenyin") and attacker:getMark("&luafenyin!") >= 3)
							or (attacker:hasSkills("xingyao_if") and countCheer(attacker) >= 5)
							or (attacker:hasSkill("roulin") and player:isFemale())
							or (player:hasSkill("roulin") and attacker:isFemale())
							or (jiangqin and jiangqin:isAdjacentTo(player) and attacker:isAdjacentTo(player) and self and self:isFriend(jiangqin, attacker))
	if need_double_jink and getKnownCard(player, attacker, "Jink", true, "he") < 2
		and getCardsNum("Jink", player) < 1.5
		and (not player:hasLordSkill("hujia") or hujiaJink < 2) then
		defense = 0
	end

	--if attacker:hasSkills("libeng") and player:getHandcardNum() < 2 then
	--	defense = 0
	--end

	if attacker:hasSkill("dahe") and player:hasFlag("dahe") and getKnownCard(player, attacker, "Jink", true, "he") == 0 and getKnownNum(player) == player:getHandcardNum()
		and not (player:hasLordSkill("hujia") and hujiaJink >= 1) then
		defense = 0
	end

	local jink = sgs.Sanguosha:cloneCard("jink")
	if player:isCardLimited(jink, sgs.Card_MethodUse) then defense = 0 end
	jink:deleteLater()

	if player:hasFlag("QianxiTarget") then
		local red = player:getMark("@qianxi_red") > 0
		local black = player:getMark("@qianxi_black") > 0
		if red then
			if player:hasSkill("qingguo") or (player:hasSkill("longhun") and player:isWounded()) then
				defense = defense - 1
			else
				defense = 0
			end
		elseif black then
			if player:hasSkill("qingguo") then
				defense = defense - 1
			end
		end
	end

	defense = defense + math.min(player:getHp() * 0.45, 10)

	if attacker and not attacker:hasSkill("jueqing") then
		local m = sgs.masochism_skill:split("|")
		for _, masochism in ipairs(m) do
			if player:hasSkill(masochism) and sgs.isGoodHp(player) then
				defense = defense + 1
			end
		end
		if player:hasSkill("jieming") then defense = defense + 4 end
		if player:hasSkills("yiji|jiexin|chuangshi") then defense = defense + 4 end
		if player:hasSkill("guixin") then defense = defense + 4 end
		if player:hasSkill("yuce") then defense = defense + 2 end
		if player:hasSkills("xuelin|yonglan|xunyi|chushou") then defense = defense + 2 end
	end

	if not sgs.isGoodTarget(player) then defense = defense + 10 end

	if player:hasSkills("nosrende|rende") and player:getHp() > 2 then defense = defense + 1 end
	if player:hasSkill("kuanggu") and player:getHp() > 1 then defense = defense + 0.2 end
	if player:hasSkill("zaiqi") and player:getHp() > 1 then defense = defense + 0.35 end
	if player:hasSkill("tianming") then defense = defense + 0.1 end

	if player:getHp() > getBestHp(player) then defense = defense + 0.8 end
	if player:getHp() <= 2 then defense = defense - 0.4 end

	local playernum = global_room:alivePlayerCount()
	if (player:getSeat() - attacker:getSeat()) % playernum >= playernum - 2 and playernum > 3 and player:getHandcardNum() <= 2 and player:getHp() <= 2 then
		defense = defense - 0.4
	end

	if player:hasSkills("tianxiang|ol_tianxiang") then defense = defense + player:getHandcardNum() * 0.5 end

	if player:getHandcardNum() == 0 and hujiaJink == 0 and not player:hasSkill("kongcheng") then
		if player:getHp() <= 1 then defense = defense - 2.5 end
		if player:getHp() == 2 then defense = defense - 1.5 end
		if not hasEightDiagram then defense = defense - 2 end
		if attacker:hasWeapon("guding_blade") and player:getHandcardNum() == 0
		  and not (player:hasArmorEffect("silver_lion") and not IgnoreArmor(attacker, player)) then
			defense = defense - 2
		end
	end

--	local has_fire_slash
--	local cards = sgs.QList2Table(attacker:getHandcards())
--	for i = 1, #cards, 1 do
--		if (attacker:hasWeapon("fan") and cards[i]:objectName() == "slash" and not cards[i]:isKindOf("ThunderSlash")) or cards[i]:isKindOf("FireSlash")  then
--			has_fire_slash = true
--			break
--		end
--	end

	--重寫對藤甲防禦
	if player:hasArmorEffect("vine") and not IgnoreArmor(attacker, player) and attacker:canSlash(player)
	and self and (self:getCardId("FireSlash") or (self:getCardId("Slash") and attacker:hasWeapon("fan")))
	then
		defense = defense - 0.6
	end

	if isLord(player) then
		defense = defense - 0.4
		if sgs.isLordInDanger() then defense = defense - 0.7 end
	end

	if not player:faceUp() then defense = defense - 0.35 end

	if player:containsTrick("indulgence") and not player:containsTrick("YanxiaoCard") then defense = defense - 0.15 end
	if player:containsTrick("supply_shortage") and not player:containsTrick("YanxiaoCard") then defense = defense - 0.15 end

	if (attacker:hasSkill("roulin") and player:isFemale()) or (attacker:isFemale() and player:hasSkill("roulin")) then
		defense = defense - 2.4
	end

	if not hasEightDiagram then
		if player:hasSkill("jijiu") then defense = defense - 3 end
		if player:hasSkill("dimeng") then defense = defense - 2.5 end
		if player:hasSkill("guzheng") and knownJink == 0 then defense = defense - 2.5 end
		if player:hasSkills("qiaobian|fahun") then defense = defense - 2.4 end
		if player:hasSkill("jieyin") then defense = defense - 2.3 end
		if player:hasSkills("noslijian|lijian") then defense = defense - 2.2 end
		if player:hasSkill("nosmiji") and player:isWounded() then defense = defense - 1.5 end
		if player:hasSkill("xiliang") and knownJink == 0 then defense = defense - 2 end
		if player:hasSkill("shouye") then defense = defense - 2 end
	end
	return defense
end

sgs.ai_compare_funcs["defenseSlash"] = function(a, b)
	return sgs.getDefenseSlash(a) < sgs.getDefenseSlash(b)
end

function SmartAI:slashProhibit(card, enemy, from)
	local mode = self.room:getMode()
	if mode:find("_mini_36") then return self.player:hasSkill("keji") end
	--card = card or sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	local is_clone_card = false
	if not card then
		card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		is_clone_card = true
	end
	from = from or self.player
	
	local function before_return()
		if is_clone_card then
			card:deleteLater()
		end
	end
	
	if self.room:isProhibited(from, enemy, card) then before_return() return true end
	local nature = card:isKindOf("FireSlash") and sgs.DamageStruct_Fire
					or card:isKindOf("ThunderSlash") and sgs.DamageStruct_Thunder
					or card:isKindOf("IceSlash") and sgs.DamageStruct_Ice
	if not self.player:hasFlag("slashProhibit_stack_overflow") then
		for _, askill in sgs.qlist(enemy:getVisibleSkillList(true)) do
			local filter = sgs.ai_slash_prohibit[askill:objectName()]
			if filter and type(filter) == "function" and filter(self, from, enemy, card) then before_return() return true end
		end
	end
	
	if self:isFriend(enemy, from) then
		if card:isKindOf("FireSlash") or from:hasWeapon("fan") or from:hasSkill("zonghuo") then
			if enemy:hasArmorEffect("vine") and not (enemy:isChained() and self:isGoodChainTarget(enemy, from, nil, nil, card)) then before_return() return true end
		end
		if enemy:isChained() and (card:isKindOf("NatureSlash") or from:hasSkill("zonghuo")) and self:slashIsEffective(card, enemy, from)
			and (not self:isGoodChainTarget(enemy, from, nature, nil, card) and not from:hasSkill("jueqing")) then before_return() return true end
		if getCardsNum("Jink",enemy, from) == 0 and enemy:getHp() < 2 and self:slashIsEffective(card, enemy, from) then before_return() return true end
		if enemy:isLord() and self:isWeak(enemy) and self:slashIsEffective(card, enemy, from) then before_return() return true end
		if from:hasWeapon("gudingblade") and enemy:isKongcheng() then before_return() return true end
	else
		if (card:isKindOf("NatureSlash") or from:hasSkill("zonghuo")) and not from:hasSkill("jueqing") and enemy:isChained()
			and not self:isGoodChainTarget(enemy, from, nature, nil, card) and self:slashIsEffective(card, enemy, from) then
			before_return() return true
		end
	end
	
	before_return()

	return not self:slashIsEffective(card, enemy, from) -- @todo: param of slashIsEffective
end

function SmartAI:canLiuli(other, another)
	if not other:hasSkills("liuli|guizhou") then return false end
	if type(another) == "table" then
		if #another == 0 then return false end
		for _, target in ipairs(another) do
			if target:getHp() < 3 and self:canLiuli(other, target) then return true end
		end
		return false
	end

	if not self:needToLoseHp(another, self.player, true) or not self:getDamagedEffects(another, self.player, true) then return false end
	if other:hasSkill("liuli") then
		local n = other:getHandcardNum()
		if n > 0 and (other:distanceTo(another) <= other:getAttackRange()) then return true
		elseif other:getWeapon() and other:getOffensiveHorse() and (other:distanceTo(another) <= other:getAttackRange()) then return true
		elseif other:getWeapon() or other:getOffensiveHorse() then return other:distanceTo(another) <= 1
		else return false end
	elseif other:hasSkill("guizhou") then
		return another:inMyAttackRange(other)
	end
	return false
end

function SmartAI:slashIsEffective(slash, to, from, ignore_armor, ignore_skills)
	if not slash or not to then self.room:writeToConsole(debug.traceback()) return end
	from = from or self.player
	if not ignore_skills then
		if to:hasSkill("zuixiang") and to:isLocked(slash) then return false end
		if to:hasSkills("yizhong|bingshen") and not to:getArmor() then
			if slash:isBlack() then
				return false
			end
		end
		if to:hasSkill("zhenre") and (slash:getSuit() == sgs.Card_Heart or slash:getSuit() == sgs.Card_Spade) then	--蓁惹红桃黑桃杀无效
			return false
		end
		if to:hasSkill("bingshen") and slash:isBlack() then	--冰身黑杀无效
			return false
		end
		if to:hasSkill("fagun") and to:getMark("@fagun_effect") > 0 and slash:isRed() then return false end	--法棍红杀无效
	end
	if to:hasArmorEffect("god_diagram") then
		return false
	end
	if not ignore_skills and to:hasSkill("xiemu") and slash:isBlack() and to:getMark("@xiemu_" .. from:getKingdom()) > 0 then return false end
	if to:getMark("@late") > 0 then return false end

	local natures = {
		Slash = sgs.DamageStruct_Normal,
		FireSlash = sgs.DamageStruct_Fire,
		ThunderSlash = sgs.DamageStruct_Thunder,
		IceSlash = sgs.DamageStruct_Ice,
	}

	local nature = natures[slash:getClassName()]
	self.equipsToDec = sgs.getCardNumAtCertainPlace(slash, from, sgs.Player_PlaceEquip)
	if from:hasSkill("zonghuo") then nature = sgs.DamageStruct_Fire end
	local eff = self:damageIsEffective(to, nature, from, slash)
	self.equipsToDec = 0
	if not eff then return false end

	if not ignore_armor and from:objectName() == self.player:objectName() then
--以下的self:askForCardChosen(to, "he", "moukui")容易進入死循環(slashProhibit找slashIsEffective，然後slashIsEffective又回來再找slashProhibit)。
--為了穩定遊戲，已下都改寫為 "ignore_armor = true"，只要有棄置任何一張裝備牌就好。(將一張殺當過河拆橋也不錯)
--		if to:getArmor() and from:hasSkill("moukui") then
--			if not self:isFriend(to) or self:needToThrowArmor(to) then
--				if not (self:isEnemy(to) and self:doNotDiscard(to)) then
--					local id = self:askForCardChosen(to, "he", "moukui")
--					if id == to:getArmor():getEffectiveId() then ignore_armor = true end
--				end
--			end
--		end
--
		--注：改以下時要同時改function SmartAI:needToThrowArmor(player)中的local FS = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)下面那一堆條件
		--在 [not self.player:hasSkill("moukui")] 後加上可以忽略防具的技能
		--這樣改的原因
		--1.防止死循環[self:slashProhibit(FS, player, self.player)的slashProhibit找slashIsEffective，然後slashIsEffective又回來再找slashProhibit]，會造成無窮迴圈死循環使AI卡住不出牌
		--2.能火殺藤甲的時後，這些武將可以選擇增傷
		--補充：SmartAI:askForCardChosen有很多self:needToThrowArmor(who, reason == "moukui")，目前不增加另外的技能，因AI如其運作
		
		--改寫謀潰無視防具
		--增加其他無視防具技能
		if to:getArmor() and (from:hasSkills("moukui|jianchu|olpojun|wuniang|xingyao") or (from:hasSkill("longxi") and from:getMark("longxi_used") == 0)) then
			if not self:isFriend(to) or self:needToThrowArmor(to) then
				if not (self:isEnemy(to) and self:doNotDiscard(to)) then
					ignore_armor = true
				end
			end
		end
	end

	if IgnoreArmor(from, to) or ignore_armor then
		return true
	end

	if not ignore_skills then
		--排除郭圖＆逢紀飾非技能
		local current_shifei = self.room:getCurrent()
		local shifei_max_handcard_num = 0
		local shifei_targets = {}
		if current_shifei then
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
--				if p:objectName() == current_shifei:objectName() then
--					shifei_max_handcard_num = math.max(shifei_max_handcard_num, p:getHandcardNum() + 1)
--				else
					shifei_max_handcard_num = math.max(shifei_max_handcard_num, p:getHandcardNum())
--				end
			end
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
--				if p:objectName() == current_shifei:objectName() then
--					if p:getHandcardNum() + 1 == shifei_max_handcard_num then
--						table.insert(shifei_targets, p)
--					end
--				else
					if p:getHandcardNum() == shifei_max_handcard_num then
						table.insert(shifei_targets, p)
					end
--				end
			end
			if to:hasSkill("shifei") then
				local can_use_shifei = true
				for _,shifei_target in ipairs(shifei_targets) do
					if shifei_target:objectName() == current_shifei:objectName() and (sgs.GetConfig("shifei_down", true) and #shifei_targets == 1 or true) then
						can_use_shifei = false
					end
				end
				if can_use_shifei then
					for _,shifei_target in ipairs(shifei_targets) do
						if self:isFriend(shifei_target) then
							return false
						end
					end
				end
			end
		end
		--排除司馬昭怠攻技能，AI打司馬昭
		if to and from and to:hasSkill("daigong") and not from:hasSkill("jueqing") and to:getHandcardNum() > 3 then return false end
		--杜畿安東殺無效
		local attacker_has_peach = false
		if from then
			for _,c in ipairs(sgs.QList2Table(from:getCards("h"))) do
				if c:getSuit() == sgs.Card_Heart and c:isKindOf("Peach") then
					attacker_has_peach = true
				end
			end
		end
		if to and from and to:hasSkill("andong") and (attacker_has_peach or from:isKongcheng()) then return false end
		if from and slash and slash:getSkillName() == "spear" and to:hasSkill("andong") and from:getHandcardNum() == 2 then return false end
		--排除司馬徽隱士技能，AI打司馬徽
		if to and from and to:hasSkill("yinshi") and not from:hasSkill("jueqing") and slash:isKindOf("NatureSlash") and to:getMark("@dragon") + to:getMark("@phoenix") == 0 and not to:getArmor() then return false end
		--排除TW馬良白眉，AI打TW馬良
		if to and from and to:hasSkill("twyj_baimei") and not from:hasSkill("jueqing") and slash:isKindOf("NatureSlash") and to:isKongcheng() then return false end
		--紅棉百花袍
		if to and from and not IgnoreArmor(from, to) and to:getArmor() and to:getArmor():isKindOf("RedCottonHundredFlowerRobe") and slash:isKindOf("NatureSlash") then return false end
		--劉禪享樂技能1張基本牌殺無效
		local basicnum = 0
		local basicnum_notovert = 0
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		for _, c in ipairs(handcards) do
			if c:getTypeId() == sgs.Card_TypeBasic and not c:isKindOf("Peach") then
				basicnum = basicnum + 1
				if not c:isOvert() then
					basicnum_notovert = basicnum_notovert + 1
				end
			end
		end
		if slash:isOvert() then
			basicnum_notovert = basicnum_notovert - 1
		end
		if to:hasSkill("xiangle") and basicnum < 2 then return false end
		if to:hasSkill("yujie") and to:getMark("&yujie+_lun!") < 3 and basicnum_notovert < 1 then return false end	--域界
	end
	
	if to:hasArmorEffect("renwang_shield") and slash:isBlack() then return false end
	if to:hasArmorEffect("renwang_shield") and to:getMark("jingxie_RenwangShield_id_"..to:getArmor():getEffectiveId()) > 0 and (slash:isBlack() or slash:getSuit() == sgs.Card_Heart) then return false end
	if to:hasArmorEffect("vine") and not slash:isKindOf("NatureSlash") then
		local skill_name = slash:getSkillName() or ""
		local can_convert = false
		if skill_name == "guhuo" then
			can_convert = true
		else
			local skill = sgs.Sanguosha:getSkill(skill_name)
			if not skill or skill:inherits("FilterSkill") then
				can_convert = true
			end
		end
		return can_convert and (from:hasWeapon("fan") or from:hasSkill("zonghuo") or (from:hasSkill("lihuo") and not self:isWeak(from)))
	end

	if slash:isKindOf("ThunderSlash") or slash:isKindOf("IceSlash") then
		local f_slash = self:getCard("FireSlash")
		if f_slash and self:hasHeavySlashDamage(from, f_slash, to, true) > self:hasHeavySlashDamage(from, slash, to, true)
			and (not to:isChained() or self:isGoodChainTarget(to, from, sgs.DamageStruct_Fire, nil, f_slash)) then
			return self:slashProhibit(f_slash, to, from)
		end
	elseif slash:isKindOf("FireSlash") then
		local t_slash = self:getCard("ThunderSlash")
		if t_slash and self:hasHeavySlashDamage(from, t_slash, to, true) > self:hasHeavySlashDamage(from, slash, to, true)
			and (not to:isChained() or self:isGoodChainTarget(to, from, sgs.DamageStruct_Thunder, nil, t_slash)) then
			return self:slashProhibit(t_slash, to, from)
		end
	end

	return true
end

function SmartAI:slashIsAvailable(player, slash) -- @todo: param of slashIsAvailable
	player = player or self.player
	slash = slash or self:getCard("Slash", player)
	local is_clone_card = false
	if not slash or not slash:isKindOf("Slash") then
		is_clone_card = true
		slash = sgs.Sanguosha:cloneCard("slash")
	end
	assert(slash)
	local result = slash:isAvailable(player)
	if is_clone_card then
		slash:deleteLater()
	end
	return result
end

function sgs.isJinkAvailable(from, to, slash, judge_considered)
	return not (
			(not judge_considered and from:hasSkills("tieji|nostieji|xianzhi"))
			or (from:hasSkill("liegong") and from:getPhase() == sgs.Player_Play
				and (to:getHandcardNum() <= from:getAttackRange() or to:getHandcardNum() >= from:getHp()))
			or (from:hasSkill("kofliegong") and from:getPhase() == sgs.Player_Play and to:getHandcardNum() >= from:getHp())
			or (from:getMark("zhaxiang") > 0 and slash and slash:isRed())
			or (from:hasSkill("ol_liegong") and to:getHandcardNum() <= from:getHandcardNum())
			or (from:hasSkill("wenji") and slash and from:getMark("wenji"..slash:getClassName().."-Clear") > 0)
			or (from:hasSkill("wanglie") and slash and slash:hasFlag("wanglie"))
			or (from:hasSkill("hunyin") and from:getMark("&hunyin_buff") > 0)	--混音
			or (from:hasSkill("santan") and from:getMark("santan_counter") == 2)	--三叹
			or (from:getPile("moci"):length() > 0 and from:getPile("moci"):length() > to:getHandcardNum())	--魔刺
			or (from:getMark("&libeng") > 0)	--礼崩（新版）
			)

	--[[
	return (not judge_considered and from:hasSkills("tieji|nostieji"))
			or (from:hasSkill("liegong") and from:getPhase() == sgs.Player_Play
				and (to:getHandcardNum() <= from:getAttackRange() or to:getHandcardNum() >= from:getHp()))
			or (from:hasSkill("kofliegong") and from:getPhase() == sgs.Player_Play and to:getHandcardNum() >= from:getHp())
			or (from:getMark("zhaxiang") > 0 and slash and slash:isRed())
	]]--
end

function SmartAI:findWeaponToUse(enemy)
	local weaponvalue = {}
	local hasweapon
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("Weapon") then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useEquipCard(c, dummy_use)
			if dummy_use.card then
				weaponvalue[c] = self:evaluateWeapon(c, self.player, enemy)
				hasweapon = true
			end
		end
	end
	if not hasweapon then return end
	if self.player:getWeapon() then weaponvalue[self.player:getWeapon()] = self:evaluateWeapon(self.player:getWeapon(), self.player, enemy) end
	local max_value, max_card = -1000
	for c, v in pairs(weaponvalue) do
		if v > max_value then max_card = c max_value = v end
	end
	if self.player:getWeapon() and self.player:getWeapon():getEffectiveId() == max_card:getEffectiveId() then return end
	return max_card
end

function SmartAI:isPriorFriendOfSlash(friend, card, source)		--优先对队友使用杀
	source = source or self.player
	local huatuo = self.room:findPlayerBySkillName("jijiu")
	if not self:hasHeavySlashDamage(source, card, friend) and card:getSkillName() ~= "lihuo" and sgs.isJinkAvailable(source, friend, card)
			and ((self:findLeijiTarget(friend, 50, source, -1) or (self:findLeijiTarget(friend, 50, source, 1) and friend:isWounded()))
				or (friend:isLord() and source:hasSkill("guagu") and friend:getLostHp() >= 1 and getCardsNum("Jink", friend, source) == 0)
				or (friend:hasSkill("jieming") and source:hasSkill("nosrende") and (huatuo and self:isFriend(huatuo, source)))
				or (friend:hasSkill("hunzi") and friend:getHp() == 2 and self:getDamagedEffects(friend, source)))
				or self:hasNosQiuyuanEffect(source, friend)
				or (friend:hasSkill("guixin") and not friend:faceUp() and friend:getHp() > 1 and not friend:containsTrick("indulgence"))
				or (friend:hasSkills("xianwei|yongning|youlian|fuyu|shixi|zhongyu|luafenyin") and self:needToLoseHp(friend))
				or (friend:hasSkill("chouzhen") and friend:getChangeSkillState("chouzhen") == 2 and friend:getHp() > 2 and sgs.ai_need_damaged["chouzhen"](self, source, friend))
				or (friend:hasSkill("milian") and friend:getMark("milian") == 0 and friend:hasSkill("qicheng") and self.room:getTag("TurnLengthCount"):toInt() <= 2 and self:needToLoseHp(friend))
				then
		return true
	end
	if not source:hasSkill("jueqing") and friend:getMark("@orange") == 0 and card:isKindOf("NatureSlash") and friend:isChained() and self:isGoodChainTarget(friend, source, nil, nil, card) then return true end
	return
end

function SmartAI:useCardSlash(card, use)
	if not use.isDummy and not self:slashIsAvailable(self.player, card) then return end
	
	if card:getSkillName() == "quanneng" then	--全能杀，避免空气杀
		local to = self:findPlayerToSlash(true, card, nil, true)		--距离限制、卡牌、角色限制、必须选择
		if to then
			use.card = card
			if (use.to) then use.to:append(to) end
			return
		end
	end
	
	--新增詐降和鬼龍斬月刀最優先使用紅色殺
	if self.player:getMark("zhaxiang") > 0 or (self.player:getWeapon() and self.player:getWeapon():isKindOf("GodBlade")) then
		local red_slash_card_num = 0
		for _,c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
			if c:isKindOf("Slash") and c:isRed() then
				red_slash_card_num = red_slash_card_num + 1
			end
		end
		if red_slash_card_num > 0 and card:isBlack() then return end
	end

	local basicnum = 0
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	for _, acard in ipairs(cards) do
		if acard:getTypeId() == sgs.Card_TypeBasic and not acard:isKindOf("Peach") then basicnum = basicnum + 1 end
	end
	local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, card) > 50
						or self.player:hasFlag("slashNoDistanceLimit")
						or card:getSkillName() == "qiaoshui"
	self.slash_targets = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
	if use.isDummy and use.extra_target then self.slash_targets = self.slash_targets + use.extra_target end
	if self.player:hasSkill("duanbing") then self.slash_targets = self.slash_targets + 1 end

	local rangefix = 0
	if card:isVirtualCard() then
		if self.player:getWeapon() and card:getSubcards():contains(self.player:getWeapon():getEffectiveId()) then
			if self.player:getWeapon():getClassName() ~= "Weapon" then
				rangefix = sgs.weapon_range[self.player:getWeapon():getClassName()] - self.player:getAttackRange(false)
			end
		end
		if self.player:getOffensiveHorse() and card:getSubcards():contains(self.player:getOffensiveHorse():getEffectiveId()) then
			rangefix = rangefix + 1
		end
	end

	local function canAppendTarget(target)
		if use.to:contains(target) then return false end
		local targets = sgs.PlayerList()
		for _, to in sgs.qlist(use.to) do
			targets:append(to)
		end
		return card:targetFilter(targets, target, self.player)
	end

	if not use.isDummy and self.player:hasSkill("qingnang") and self:isWeak() and self:getOverflow() <= 0 then return end
	for _, friend in ipairs(self.friends_noself) do
		local slash_prohibit = false
		slash_prohibit = self:slashProhibit(card, friend)
		if self:isPriorFriendOfSlash(friend, card) then
			if not slash_prohibit then
				if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
					and (self.player:canSlash(friend, card, not no_distance, rangefix)
						or (use.isDummy and self.predictedRange and (self.player:distanceTo(friend, rangefix) <= self.predictedRange)))
					and self:slashIsEffective(card, friend) then
					use.card = card
					if use.to and canAppendTarget(friend) then
						use.to:append(friend)
					end
					if not use.to or self.slash_targets <= use.to:length() then return end
				end
			end
		end
	end

	local targets = {}
	local forbidden = {}
	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if not self:slashProhibit(card, enemy) and sgs.isGoodTarget(enemy, self.enemies, self, true) and card:targetFilter(sgs.PlayerList(), enemy, self.player) then
			--這裡先targetFilter防已下狀況：
			--有兩敵人，AI可以對其中一名敵人無限出殺但AI知道殺對其無效，另一敵人正常。這狀況下，AI對正常敵人使用完殺後，會使用沒有目標的殺。(高順和界大喬)
			if self:hasNosQiuyuanEffect(self.player, enemy) or self:hasQiuyuanEffect(self.player, enemy) then table.insert(forbidden, enemy)
			elseif not self:getDamagedEffects(enemy, self.player, true) then table.insert(targets, enemy)
			else table.insert(forbidden, enemy) end
		end
	end
	if #targets == 0 and #forbidden > 0 then targets = forbidden end

	if #targets == 1 and card:getSkillName() == "lihuo" and not targets[1]:hasArmorEffect("vine") then return end

	for _, target in ipairs(targets) do
		if self.player:hasSkill("chixin") then
			local chixin_list = self.player:property("chixin"):toString():split("+")			
			if table.contains(chixin_list, target:objectName()) then continue end
		end
		local canliuli = false
		local jink = sgs.Sanguosha:cloneCard("jink")
		local use_wuqian = self.player:hasSkill("wuqian") and self.player:getMark("@wrath") >= 2
							and not target:isLocked(jink)
							and (not self.player:hasSkill("wushuang")
								or target:getArmor() and target:hasArmorEffect(target:getArmor():objectName()) and not self.player:hasWeapon("qinggang_sword"))
							and (self:hasHeavySlashDamage(self.player, card, target)
								or (getCardsNum("Jink", target, self.player) < 2 and getCardsNum("Jink", target, self.player) >= 1 and target:getHp() <= 2))
		jink:deleteLater()
		for _, friend in ipairs(self.friends_noself) do
			if self:canLiuli(target, friend) and self:slashIsEffective(card, friend) and #targets > 1 and friend:getHp() < 3 then canliuli = true end
		end
		if (not use.current_targets or not table.contains(use.current_targets, target:objectName()))
			and (self.player:canSlash(target, card, not no_distance, rangefix)
				or (use.isDummy and self.predictedRange and self.player:distanceTo(target, rangefix) <= self.predictedRange))
			and self:objectiveLevel(target) > 3
			and self:slashIsEffective(card, target, self.player, shoulduse_wuqian)
			and not (target:hasSkill("xiangle") and basicnum < 2) and not canliuli
			and not (not self:isWeak(target) and #self.enemies > 1 and #self.friends > 1 and self.player:hasSkill("keji")
				and self:getOverflow() > 0 and not self:hasCrossbowEffect()) then

			if target:getHp() > 1 and target:hasSkills("jianxiong|nitai") and self.player:hasWeapon("spear") and card:getSkillName() == "spear" then
				local ids, isGood = card:getSubcards(), true
				for _, id in sgs.qlist(ids) do
					local c = sgs.Sanguosha:getCard(id)
					if isCard("Peach", c, target) or isCard("Analeptic", c, target) then isGood = false break end
				end
				if not isGood then continue end
			end

			-- fill the card use struct
			local usecard = card
			if not use.to or use.to:isEmpty() then
				if self.player:hasWeapon("spear") and card:getSkillName() == "spear" then
				elseif self.player:hasWeapon("crossbow") and self:getCardsNum("Slash") > 1 then
				elseif not use.isDummy then
					local card = self:findWeaponToUse(target)
					if card then
						use.card = card
						return
					end
				end
				
				if target:isChained() and not use.card then
					if self:isGoodChainTarget(target, nil, nil, nil, card) then
						if not card:isKindOf("NatureSlash") then
							for _, slash in ipairs(self:getCards("Slash")) do
								if slash:isKindOf("NatureSlash") and self:slashIsEffective(slash, target)
								and not self:slashProhibit(slash, target) then
									usecard = slash
									break
								end
							end
						end
					else
						if card:isKindOf("NatureSlash") then
							for _, slash in ipairs(self:getCards("Slash")) do
								if not slash:isKindOf("NatureSlash") and self:slashIsEffective(slash, target)
								and not self:slashProhibit(slash, target) then
									usecard = slash
									break
								end
							end
						end
					end
				end

--以下邏輯錯誤
--[[
				if target:isChained() and self:isGoodChainTarget(target, nil, nil, nil, card) and not use.card then
					if self:hasCrossbowEffect() and card:isKindOf("NatureSlash") then
						local slashes = self:getCards("Slash")
						for _, slash in ipairs(slashes) do
							if not slash:isKindOf("NatureSlash") and self:slashIsEffective(slash, target)
								and not self:slashProhibit(slash, target) then
								usecard = slash
								break
							end
						end
					elseif not card:isKindOf("NatureSlash") then
						local slash = self:getCard("NatureSlash")
						if slash and self:slashIsEffective(slash, target) and not self:slashProhibit(slash, target) then usecard = slash end
					end
				end
]]--
				
				--有其他花色殺不對佐定角色出黑桃殺
				if target:hasSkill("zuoding") then
					local slashes = self:getCards("Slash")
					for _, slash in ipairs(slashes) do
						if slash:getSuit() ~= sgs.Card_Spade and self:slashIsEffective(slash, target)
							and not self:slashProhibit(slash, target) then
							usecard = slash
							break
						end
					end
				end
				
				--有黑色殺不對激昂角色出紅色殺
				if target:hasSkill("jiang") then
					local slashes = self:getCards("Slash")
					for _, slash in ipairs(slashes) do
						if slash:isBlack() and self:slashIsEffective(slash, target)
							and not self:slashProhibit(slash, target) then
							usecard = slash
							break
						end
					end
				end
				
				--有明贤时优先使用黑色普通杀
				if target:hasSkill("mingxian") then
					local slashes = self:getCards("Slash")
					for _, slash in ipairs(slashes) do
						if slash:isBlack() and not slash:isKindOf("ThunderSlash") and self:slashIsEffective(slash, target)
							and not self:slashProhibit(slash, target) then
							usecard = slash
							break
						end
					end
				end
				
				local godsalvation = self:getCard("GodSalvation")
				if not use.isDummy and godsalvation and godsalvation:getId() ~= card:getId() and self:willUseGodSalvation(godsalvation) and
					(not target:isWounded() or not self:hasTrickEffective(godsalvation, target, self.player)) then
					use.card = godsalvation
					return
				end
			end
			use.card = use.card or usecard
			if use.to and not use.to:contains(target) and canAppendTarget(target) then
				use.to:append(target)
			end
			if not use.isDummy then
				local analeptic = self:searchForAnaleptic(use, target, use.card)
				if analeptic and self:shouldUseAnaleptic(target, use.card) and analeptic:getEffectiveId() ~= card:getEffectiveId() then
					use.card = analeptic
					if use.to then use.to = sgs.SPlayerList() end
					return
				end
				if self.player:hasSkill("jilve") and self.player:getMark("@bear") > 0 and not self.player:hasFlag("JilveWansha") and target:getHp() == 1 and not self.room:getCurrent():hasSkill("wansha")
					and (target:isKongcheng() or getCardsNum("Jink", target, self.player) < 1 or sgs.card_lack[target:objectName()]["Jink"] == 1) then
					use.card = sgs.Card_Parse("@JilveCard=.")
					sgs.ai_skill_choice.jilve = "wansha"
					if use.to then use.to = sgs.SPlayerList() end
					return
				end
				if self.player:hasSkill("duyi") and self.room:getDrawPile():length() > 0 and not self.player:hasUsed("DuyiCard")
					and (target:getHp() <= 2 or self:hasHeavySlashDamage(self.player, card, target)) then
					sgs.ai_duyi = { id = self.room:getDrawPile():first(), tg = target }
					use.card = sgs.Card_Parse("@DuyiCard=.")
					if use.to then use.to = sgs.SPlayerList() end
					return
				end
				if use_wuqian then
					use.card = sgs.Card_Parse("@WuqianCard=.")
					if use.to then use.to = sgs.SPlayerList() use.to:append(target) end
					return
				end
			end
			if not use.to or self.slash_targets <= use.to:length() then return end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		--chixin這句很重要，不然J.SP趙雲會空氣殺
		if self.player:hasSkill("chixin") then
			local chixin_list = self.player:property("chixin"):toString():split("+")			
			if table.contains(chixin_list, friend:objectName()) then continue end
		end
		local slash_prohibit = self:slashProhibit(card, friend)
		if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
			and not self:hasHeavySlashDamage(self.player, card, friend) and card:getSkillName() ~= "lihuo"
			and (not use.to or not use.to:contains(friend))
			and ((self.player:hasSkill("pojun") and friend:getHp() > 4 and getCardsNum("Jink", friend, self.player) == 0 and friend:getHandcardNum() < 3)
				or (self:getDamagedEffects(friend, self.player) and not (friend:isLord() and #self.enemies < 1))
				or (self:needToLoseHp(friend, self.player, true, true) and not (friend:isLord() and #self.enemies < 1))) then

			if not slash_prohibit then
				if ((self.player:canSlash(friend, card, not no_distance, rangefix))
					or (use.isDummy and self.predictedRange and self.player:distanceTo(friend, rangefix) <= self.predictedRange))
					and self:slashIsEffective(card, friend) then
					use.card = card
					if use.to and canAppendTarget(friend) then
						use.to:append(friend)
					end
					if not use.to or self.slash_targets <= use.to:length() then return end
				end
			end
		end
	end
end

sgs.ai_skill_use.slash = function(self, prompt)
	local parsedPrompt = prompt:split(":")
	local callback = sgs.ai_skill_cardask[parsedPrompt[1]] -- for askForUseSlashTo
	if self.player:hasFlag("slashTargetFixToOne") and type(callback) == "function" then
		local slash
		local target
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("SlashAssignee") then target = player break end
		end
		local target2 = nil
		if #parsedPrompt >= 3 then target2 = findPlayerByObjectName(self.room, parsedPrompt[3]) end
		if not target then return "." end
		local ret = callback(self, nil, nil, target, target2, prompt)
		if ret == nil or ret == "." then return "." end
		slash = sgs.Card_Parse(ret)
		local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50 or self.player:hasFlag("slashNoDistanceLimit")
		local targets = {}
		local use = { to = sgs.SPlayerList() }
		if self.player:canSlash(target, slash, not no_distance) then use.to:append(target) else return "." end

		if parsedPrompt[1] ~= "@niluan-slash" and target:hasSkill("xiansi") and target:getPile("counter"):length() > 1
			and not (self:needKongcheng() and self.player:isLastHandCard(slash, true)) then
			return "@XiansiSlashCard=.->" .. target:objectName()
		end
		if not slash:isVirtualCard() then
		--主要防止對趙襄借刀殺人時，趙襄芳魂(LUA技能卡)殺閃退。C++技能卡沒有這問題。
		--BUG描述：
		--useCardSlash中，有table.insert到和此段targets一樣名稱的表時會閃退。
		--useCardSlash中，card:targetFilter(sgs.PlayerList(), enemy, self.player)部分會閃退。
			self:useCardSlash(slash, use)
		end
		
		for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end
		if table.contains(targets, target:objectName()) then return ret .. "->" .. table.concat(targets, "+") end
		return "."
	end
	
	local useslash, target
	local slashes = self:getCards("Slash")
	
	if parsedPrompt[1] == "#zuoye_slash_use" then	--作业要求出杀的特殊情况
		if not self.player:faceUp() then	--背面向上的角色被作业要求出杀时，默认不出以翻回
			return "."
		else								--正面向上且要求对队友出杀时，若自己手牌数多于5且对方没有生命危险，则强行出杀
			local to
			for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if player:hasFlag("SlashAssignee") then to = player break end
			end
			if to and self:isFriend(to) then
				if self.player:getHandcardNum() > 5 and (not self:isWeak(to, true) or getCardsNum("Jink", to, self.player) > 0) then
					for _, slash in ipairs(slashes) do
						local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50 or self.player:hasFlag("slashNoDistanceLimit")
						if self.player:canSlash(to, slash, not no_distance) and not self:slashProhibit(slash, to) then
							useslash = slash
							target = to
							break
						end
					end
				end
			end
		end
	end
	
	self:sort(self.enemies, "defenseSlash")
	for _, slash in ipairs(slashes) do
		local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50 or self.player:hasFlag("slashNoDistanceLimit")
		for _, friend in ipairs(self.friends_noself) do
			local slash_prohibit = false
			slash_prohibit = self:slashProhibit(card, friend)
			if not self:hasHeavySlashDamage(self.player, card, friend)
				and self.player:canSlash(friend, slash, not no_distance) and not self:slashProhibit(slash, friend)
				and self:slashIsEffective(slash, friend)
				and ((self:findLeijiTarget(friend, 50, source, -1) or (self:findLeijiTarget(friend, 50, source, 1) and friend:isWounded()))
					or (friend:isLord() and self.player:hasSkill("guagu") and friend:getLostHp() >= 1 and getCardsNum("Jink", friend, self.player) == 0)
					or (friend:hasSkill("jieming") and self.player:hasSkill("nosrende") and (huatuo and self:isFriend(huatuo))))
				and not (self.player:hasFlag("slashTargetFix") and not friend:hasFlag("SlashAssignee"))
				and not (slash:isKindOf("XiansiSlashCard") and friend:getPile("counter"):length() < 2) then

				useslash = slash
				target = friend
				break
			end
		end
	end
	if not useslash then
		for _, slash in ipairs(slashes) do
			local no_distance = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50 or self.player:hasFlag("slashNoDistanceLimit")
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, not no_distance) and not self:slashProhibit(slash, enemy)
					and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
					and not (self.player:hasFlag("slashTargetFix") and not enemy:hasFlag("SlashAssignee")) then

					useslash = slash
					target = enemy
					break
				end
			end
		end
	end
	if useslash and target then
		local targets = {}
		local use = { to = sgs.SPlayerList() }
		use.to:append(target)

		if target:hasSkill("xiansi") and target:getPile("counter"):length() > 1 and not (self:needKongcheng() and self.player:isLastHandCard(slash, true)) then
			return "@XiansiSlashCard=.->" .. target:objectName()
		end

		self:useCardSlash(useslash, use)
		for _, p in sgs.qlist(use.to) do table.insert(targets, p:objectName()) end
		if table.contains(targets, target:objectName()) then return useslash:toString() .. "->" .. table.concat(targets, "+") end
	end
	return "."
end

sgs.ai_skill_playerchosen.slash_extra_targets = function(self, targets)
	local slash = sgs.Sanguosha:cloneCard("slash")
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defenseSlash")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and not self:slashProhibit(slash, target) and sgs.isGoodTarget(target, targetlist, self) and self:slashIsEffective(slash, target) then
			slash:deleteLater()
			return target
		end
	end
	slash:deleteLater()
	return nil
end

sgs.ai_skill_playerchosen.zero_card_as_slash = function(self, targets)
	local slash = sgs.Sanguosha:cloneCard("slash")
	local targetlist = sgs.QList2Table(targets)
	local arrBestHp, canAvoidSlash, forbidden = {}, {}, {}
	self:sort(targetlist, "defenseSlash")

	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and not self:slashProhibit(slash ,target) and sgs.isGoodTarget(target, targetlist, self) then
			if self:slashIsEffective(slash, target) then
				if self:getDamagedEffects(target, self.player, true) or self:needLeiji(target, self.player) then
					table.insert(forbidden, target)
				elseif self:needToLoseHp(target, self.player, true, true) then
					table.insert(arrBestHp, target)
				else
					slash:deleteLater()
					return target
				end
			else
				table.insert(canAvoidSlash, target)
			end
		end
	end
	for i=#targetlist, 1, -1 do
		local target = targetlist[i]
		if not self:slashProhibit(slash, target) then
			if self:slashIsEffective(slash, target) then
				if self:isFriend(target) and (self:needToLoseHp(target, self.player, true, true)
					or self:getDamagedEffects(target, self.player, true) or self:needLeiji(target, self.player)) then
					slash:deleteLater()
					return target
				end
			else
				table.insert(canAvoidSlash, target)
			end
		end
	end
	slash:deleteLater()
	
	if #canAvoidSlash > 0 then return canAvoidSlash[1] end
	if #arrBestHp > 0 then return arrBestHp[1] end

	self:sort(targetlist, "defenseSlash")
	targetlist = sgs.reverse(targetlist)
	for _, target in ipairs(targetlist) do
		if target:objectName() ~= self.player:objectName() and not self:isFriend(target) and not table.contains(forbidden, target) then
			return target
		end
	end

	return targetlist[1]
end

sgs.ai_card_intention.Slash = function(self, card, from, tos)
	if string.find(card:getSkillName(), "m_lianjicard") then return end
	if string.find(card:getSkillName(), "xunxiao") then return end	--不记仇恨值
	
	sgs.ai_fuhuanghou_effect = false
	local current = self.room:getCurrent()
	local has_fuhuanghou = false
	local tos_count = 0
	for _, to in ipairs(tos) do
		tos_count = tos_count + 1
		if to:hasSkill("qiuyuan") then
			has_fuhuanghou = true
		end
	end
	if has_fuhuanghou and tos_count > 1 then
		sgs.ai_fuhuanghou_effect = true
		return
	end
	
	if sgs.ai_liuli_effect then
		sgs.ai_liuli_effect = false
		if sgs.ai_liuli_user then
			sgs.updateIntention(from, sgs.ai_liuli_user, 10)
			sgs.ai_liuli_user = nil
		end
		return
	end
	
	if sgs.ai_guizhou_effect then
		sgs.ai_guizhou_effect = false
		if sgs.ai_guizhou_user then
			sgs.updateIntention(from, sgs.ai_guizhou_user, 10)
			sgs.ai_guizhou_user = nil
		end
		return
	end
	
	if sgs.ai_collateral then
		sgs.ai_collateral = false
		local collateral_from_name = self.room:getTag("collateral_from_name"):toString()
		self.room:removeTag("collateral_from_name")
		local collateral_from = nil
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:objectName() == collateral_from_name then
				collateral_from = p
				break
			end
		end
		if collateral_from then
			for _, to in ipairs(tos) do
				if not self:needLeiji(to, collateral_from) then
					sgs.updateIntention(collateral_from, to, 80)
				end
			end
		end
		return
	end
	
	if card:hasFlag("nosjiefan-slash") then return end
	if card:getSkillName() == "mizhao" then return end
	for _, to in ipairs(tos) do
		local value = 80
		speakTrigger(card, from, to)
		if to:hasSkills("yiji|qiuyaun|jiexin|chuangshi") then value = 0 end
		if to:hasSkills("nosleiji|leiji|olleiji|xiaoan") and (getCardsNum("Jink", to, from) > 0 or to:hasArmorEffect("eight_diagram")) and not self:hasHeavySlashDamage(from, card, to)
			and (hasExplicitRebel(self.room) or sgs.explicit_renegade) and not self:canLiegong(to, from) then value = 0 end
		if not self:hasHeavySlashDamage(from, card, to) and (self:getDamagedEffects(to, from, true) or self:needToLoseHp(to, from, true, true)) then value = 0 end
		if from:hasSkill("pojun") and to:getHp() > (2 + self:hasHeavySlashDamage(from, card, to, true)) then value = 0 end
		if self:needLeiji(to, from) then value = from:getState() == "online" and 0 or -10 end
		if to:hasSkill("fangzhu") and to:isLord() and sgs.turncount < 2 then value = 10 end
		if to:hasSkill("guixin") and not to:faceUp() and to:getHp() > 1 and not to:containsTrick("indulgence") then value = 0 end
		sgs.updateIntention(from, to, value)
	end
end

sgs.ai_skill_cardask["slash-jink"] = function(self, data, pattern, target)
	local isdummy = type(data) == "number"
	local function getJink()
		if target and target:hasSkill("dahe") and self.player:hasFlag("dahe") then
			for _, card in ipairs(self:getCards("Jink")) do
				if card:getSuit() == sgs.Card_Heart then return card:getId() end
			end
			return "."
		end
		return self:getCardId("Jink") or not isdummy and "."
	end
	
	local slash
	local is_clone_card = false
	if type(data) == "userdata" then
		local effect = data:toSlashEffect()
		slash = effect.slash
	else
		slash = sgs.Sanguosha:cloneCard("slash")
		is_clone_card = true
	end
	
	local function before_return()
		if is_clone_card then
			slash:deleteLater()
		end
	end
	
	local cards = sgs.QList2Table(self.player:getHandcards())
	if (not target or self:isFriend(target)) and slash:hasFlag("nosjiefan-slash") then before_return() return "." end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then before_return() return "." end
	if not target then before_return() return getJink() end
	if not self:hasHeavySlashDamage(target, slash, self.player) and self:getDamagedEffects(self.player, target, slash) then before_return() return "." end
	
	--排除有大霧非雷殺出閃
	local shenzhugeliang = self.room:findPlayerBySkillName("dawu")
	if shenzhugeliang and not target:hasSkill("jueqing") and self.player:getMark("@fog") > 0 and slash and not slash:isKindOf("ThunderSlash") then before_return() return "." end
	--新神趙雲手中有酒或桃賣血摸牌
	if self.player:hasSkills("new_longhun+new_juejing") and not self:hasHeavySlashDamage(target, slash, self.player) then
		if self:getCardId("Peach") or self:getCardId("Analeptic") then
			before_return() return "."
		end
	end
	
	--已下可以注釋掉，因為sgs.ai_skill_cardask.nullfilter已經檢查元素傷害部分有沒有效。但預防萬一還是保留。
	--排除司馬徽隱士技能，AI司馬徽被打
	if slash and target and slash:isKindOf("NatureSlash") and not target:hasSkill("jueqing") and self.player:hasSkill("yinshi") and self.player:getMark("@dragon") + self.player:getMark("@phoenix") == 0 and not self.player:getArmor() then before_return() return "." end
	--排除TW馬良白眉，TW馬良被打
	if slash and target and slash:isKindOf("NatureSlash") and not target:hasSkill("jueqing") and self.player:hasSkill("twyj_baimei") and self.player:isKongcheng() then before_return() return "." end

	if slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, target, nil, nil, slash) then before_return() return "." end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player, 50, target) then before_return() return getJink() end
		if target:hasSkill("jieyin") and not self.player:isWounded() and self.player:isMale() and not self.player:hasSkills("leiji|nosleiji|olleiji") then before_return() return "." end
		if not target:hasSkill("jueqing") then
			if (target:hasSkill("nosrende") or (target:hasSkill("rende") and not target:hasUsed("RendeCard"))) and self.player:hasSkill("jieming") then before_return() return "." end
			if target:hasSkill("pojun") and not self.player:faceUp() then before_return() return "." end
		end
	else
		if self:hasHeavySlashDamage(target, slash) then before_return() return getJink() end

		local current = self.room:getCurrent()
		if current and current:hasSkill("juece") and self.player:getHp() > 0 then
			local use = false
			for _, card in ipairs(self:getCards("Jink")) do
				if not self.player:isLastHandCard(card, true) then
					use = true
					break
				end
			end
			if not use then before_return() return not isdummy and "." end
		end
		if self.player:getHandcardNum() == 1 and self:needKongcheng() then before_return() return getJink() end
		if not self:hasLoseHandcardEffective() and not self.player:isKongcheng() then before_return() return getJink() end
		if (target:hasSkill("mengjin") or slash:getSkillName() == "mingguang") and not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if self:doNotDiscard(self.player, "he", true) then before_return() return getJink() end
			if self.player:getCards("he"):length() == 1 and not self.player:getArmor() then before_return() return getJink() end
			if self.player:hasSkills("jijiu|qingnang") and self.player:getCards("he"):length() > 1 then before_return() return "." end
			if self:canUseJieyuanDecrease(target) then before_return() return "." end
			if (self:getCardsNum("Peach") > 0 or (self:getCardsNum("Analeptic") > 0 and self:isWeak()))
				and not self.player:hasSkills("tuntian+zaoxian") and not self:willSkipPlayPhase() then
				before_return() return "."
			end
		end
		if slash:getSkillName() == "fenxin_S" and self:getOverflow() >= 0 and not self:willSkipPlayPhase() and not self:isWeak(self.player, true) then		--焚心，牌多怕乐就直接不闪
			before_return() return "."
		end
		if self.player:getHp() > 1 and getKnownCard(target, self.player, "Slash") >= 1 and getKnownCard(target, self.player, "Analeptic") >= 1 and self:getCardsNum("Jink") == 1
			and (target:getPhase() < sgs.Player_Play or self:slashIsAvailable(target) and target:canSlash(self.player)) then
			before_return() return "."
		end
		if not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if target:hasWeapon("axe") then
				if target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 1 and target:getCards("he"):length() > 2 then before_return() return not isdummy and "." end
				if target:getHandcardNum() - target:getHp() > 2 and not self:isWeak() and not self:getOverflow() then before_return() return not isdummy and "." end
			elseif target:hasWeapon("blade") then
				
				local has_weak_chained_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if friend:isChained() and self:isWeak(friend) then
						has_weak_chained_friend = true
					end
				end
				if has_weak_chained_friend and slash:isKindOf("NatureSlash") and self.player:isChained() then
					before_return() return getJink()
				end
				
				if slash:isKindOf("NatureSlash") and (self.player:hasArmorEffect("vine") or self.player:hasArmorEffect("vine"))
					or self.player:hasArmorEffect("renwang_shield")
					or self:hasEightDiagramEffect()
					or self:hasHeavySlashDamage(target, slash)
					or (self.player:getHp() == 1 and #self.friends_noself == 0) then
				elseif (self:getCardsNum("Jink") <= getCardsNum("Slash", target, self.player) or self.player:hasSkill("qingnang")) and self.player:getHp() > 1
					or (self.player:hasSkill("jijiu") and getKnownCard(self.player, self.player, "red") > 0)
					or self:canUseJieyuanDecrease(target)
					then
					before_return() return not isdummy and "."
				end
			end
		end
	end
	before_return()
	return getJink()
end

sgs.dynamic_value.damage_card.Slash = true

sgs.ai_use_value.Slash = 4.5
sgs.ai_keep_value.Slash = 3.6
sgs.ai_use_priority.Slash = 2.6

function SmartAI:NeedDoubleJink(from, to)
	if from:hasSkills("wushuang") then
		return true
	end
	if from:hasSkills("luafenyin") and from:getMark("&luafenyin!") >= 3 then
		return true
	end
	if from:hasSkills("xingyao_if") and countCheer(from) >= 5 then
		return true
	end
	return false
end

function SmartAI:canHit(to, from, conservative)
	from = from or self.room:getCurrent()
	to = to or self.player
	local jink = sgs.Sanguosha:cloneCard("jink")
	if to:isCardLimited(jink, sgs.Card_MethodUse) then
		jink:deleteLater()
		return true
	end
	jink:deleteLater()
	if self:canLiegong(to, from) then return true end
	if not self:isFriend(to, from) then
		if from:hasWeapon("axe") and from:getCards("he"):length() > 2 then return true end
		if from:hasWeapon("blade") and getCardsNum("Jink", to, from) <= getCardsNum("Slash", from, from) then return true end
		if from:hasSkill("mengjin") and not (from:hasSkill("nosqianxi") and not from:hasSkill("jueqing") and from:distanceTo(to) == 1)
			and not self:hasHeavySlashDamage(from, nil, to) and not self:needLeiji(to, from) then
				if self:doNotDiscard(to, "he", true) then
				elseif to:getCards("he"):length() == 1 and not to:getArmor() then
				elseif self:canUseJieyuanDecrease(from, to) then return false
				elseif self:willSkipPlayPhase() then
				elseif (getCardsNum("Peach", to, from) > 0 or getCardsNum("Analeptic", to, from) > 0) then return true
				elseif not self:isWeak(to) and to:getArmor() and not self:needToThrowArmor() then return true
				elseif not self:isWeak(to) and to:getDefensiveHorse() then return true
				end
		end
	end

	local hasHeart, hasRed, hasBlack
	for _, card in ipairs(self:getCards("Jink"), to) do
		if card:getSuit() == sgs.Card_Heart then hasHeart = true end
		if card:isRed() then hasRed = true end
		if card:isBlack() then hasBlack = true end
	end
	if to:hasFlag("dahe") and not hasHeart then return true end
	if to:getMark("@qianxi_red") > 0 and not hasBlack then return true end
	if to:getMark("@qianxi_black") > 0 and not hasRed then return true end
	if not conservative and self:hasHeavySlashDamage(from, nil, to) then conservative = true end
	if not conservative and (from:hasSkill("moukui") or (from:hasSkill("longxi") and from:getMark("longxi_used") == 0)) then conservative = true end
	if not conservative and self:hasEightDiagramEffect(to) and not IgnoreArmor(from, to) then return false end
--	local need_double_jink = from and (from:hasSkill("wushuang")
--			or (from:hasSkill("roulin") and to:isFemale()) or (from:isFemale() and to:hasSkill("roulin")))
	
	--考慮木牛流馬中有閃
	local wooden_ox_jink = 0
	for _, id in sgs.qlist(to:getPile("wooden_ox")) do
		if sgs.Sanguosha:getCard(id):isKindOf("Jink") then
			wooden_ox_jink = wooden_ox_jink + 1
		end
	end
	
	--if from:hasSkills("libeng") and to:getHandcardNum() < 2 and wooden_ox_jink == 0 then return true end
	if from:hasSkills("fenxin_S") and self:getOverflow(to) > 0 and not self:willSkipPlayPhase(to) and not self:isWeak(to) then return true end
	
	if to:objectName() == self.player:objectName() then
		if self:NeedDoubleJink(from, to) and getCardsNum("Jink", to, from) + wooden_ox_jink < 2 then return true end
		if getCardsNum("Jink", to, from) + wooden_ox_jink < 1 then return true end
	end
	if self:NeedDoubleJink(from, to) and getCardsNum("Jink", to, from) + wooden_ox_jink < 2 then return true end
	if getCardsNum("Jink", to, from) + wooden_ox_jink < 1 then return true end
	
	return false
end

function SmartAI:useCardPeach(card, use)
	local mustusepeach = false
	if not self.player:isWounded() then return end

	--有營的標記下不留桃
	if self.player:getMark("@thiefed") > 0 and not self.player:hasSkill("jieyingy") and self.room:findPlayerBySkillName("jieyingy") then
		use.card = card
		return
	end
	
	--讓SP夏侯氏燕語基本牌時瘋狂吃桃
	local xiahoushi = self.room:findPlayerBySkillName("yanyu")
	if xiahoushi and self:isFriend(xiahoushi) and xiahoushi:getMark("YanyuDiscard1") > 0 then
		use.card = card
		return
	end
	
	--被鎮骨要棄桃時吃桃
	if self.player:getMark("@zhengu") > 0 then
		local zhengu_max_card = 1000
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:hasSkill("zhengu") then
				zhengu_max_card = p:getHandcardNum()
			end
		end
		if self:getCardsNum("Peach") > zhengu_max_card then
			use.card = card
			return
		end
	end
	
	if self.player:hasSkill("yongsi") and self:getCardsNum("Peach") > self:getOverflow(nil, true) then
		use.card = card
		return
	end

	--需要回复到最佳体力，吃桃
	if self.player:getHp() < getBestHp(self.player) and self.player:getLostHp() > 0 then
		use.card = card
		return
	end
	
	--没有队友且自己溢出，吃桃
	if #self.friends_noself == 0 and self:getOverflow() > 0 then
		use.card = card
		return
	end
	
	if self.player:hasSkill("longhun") and not self.player:isLord() and
	--math.min(self.player:getMaxCards(), self.player:getHandcardNum()) + self.player:getCards("e"):length() > 3 then return end
	self.player:getHandcardNum() <= self.player:getMaxCards() then return end
	
	if self.player:hasSkill("new_longhun") and self.player:getHandcardNum() <= self.player:getMaxCards() then return end

	local peaches = 0
	local cards = self.player:getHandcards()
	local lord= getLord(self.player)

	cards = sgs.QList2Table(cards)
	for _,card in ipairs(cards) do
		if isCard("Peach", card, self.player) then peaches = peaches + 1 end
	end

	if self.player:isLord() and (self.player:hasSkill("hunzi") and self.player:getMark("hunzi") == 0)
		and self.player:getHp() < 4 and self.player:getHp() > peaches then return end

	if (self.player:hasSkill("nosrende") or (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard"))) and self:findFriendsByType(sgs.Friend_Draw) then return end

	if self.player:hasArmorEffect("silver_lion") then
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Armor") and self:evaluateArmor(card) > 0 then
				use.card = card
				return
			end
		end
	end

	local SilverLion, OtherArmor
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("SilverLion") then
			SilverLion = card
		elseif card:isKindOf("Armor") and not card:isKindOf("SilverLion") and self:evaluateArmor(card) > 0 then
			OtherArmor = true
		end
	end
	if SilverLion and OtherArmor then
		use.card = SilverLion
		return
	end

	for _, enemy in ipairs(self.enemies) do
		if self.player:getHandcardNum() < 3 and
				(self:hasSkills(sgs.drawpeach_skill,enemy) or getCardsNum("Dismantlement", enemy) >= 1
					or enemy:hasSkill("jixi") and enemy:getPile("field"):length() >0 and enemy:distanceTo(self.player) == 1
					or enemy:hasSkill("qixi") and getKnownCard(enemy, self.player, "black", nil, "he") >= 1
					or getCardsNum("Snatch", enemy) >= 1 and enemy:distanceTo(self.player) == 1
					or (enemy:hasSkill("tiaoxin") and (self.player:inMyAttackRange(enemy) and self:getCardsNum("Slash") < 1 or not self.player:canSlash(enemy)))
					or (enemy:hasSkill("lihun") and self.player:isMale())
					or enemy:hasSkills("yijue|fanjian|tianyi|jianchu|lieren|dimeng|gongxin|guixin|xianzhen|anxu|zhuikong|qiaoshui|xiansi|danshou|olpojun|olanxu|dahe|tanhu|yinling|gushe|xiashu|fenyue|zhidao|kuangbi|duliang|qinqing|jiyu|zhuandui|wenji|yaoming|guolun|ol_youdi|kannan|cuike|zuilun|zhengu|liangyin|lueming|tanbei|wuniang")
					or enemy:hasSkills("libeng|chongya|suoqiu|newmoyin")
					or (sgs.GetConfig("starfire", true) and enemy:hasSkill("liyu"))
				)
				then
			mustusepeach = true
			break
		end
	end

	local jinxuandi = self.room:findPlayerBySkillName("wuling")
	if jinxuandi and jinxuandi:getMark("@water") > 0 and self.player:getLostHp() >= 2 then
		mustusepeach = true
	end

	if self.player:getHp() == 1 and not (lord and self:isFriend(lord) and lord:getHp() < 2 and self:isWeak(lord)) then
		mustusepeach = true
	end

	if mustusepeach or (self.player:hasSkill("nosbuqu") and self.player:getHp() < 1 and self.player:getMaxCards() == 0) or peaches > self.player:getHp() then
		use.card = card
		return
	end
	
	--周泰手牌上限大於或等於桃數時不使用桃
	local buqu = self.player:getPile("trauma")
	if self.player:hasSkill("buqu") then
		if not buqu:isEmpty() then
			if self.player:getMaxCards() >= self:getCardsNum("Peach") and #self.friends_noself > 0 then return end
		end
	end
	--唐咨-第二版興棹跳過棄牌不用桃
	local wounded_num = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:isWounded() then
			wounded_num = wounded_num + 1
		end
	end
	if self.player:hasSkill("sec_xingzhao") and wounded_num >= 3 and #self.friends_noself > 0 then return end

	if self:getOverflow() <= 0 and #self.friends_noself > 0 then
		return
	end

	if self.player:hasSkill("kuanggu") and not self.player:hasSkill("jueqing") and self.player:getLostHp()==1 and self.player:getOffensiveHorse() then
		return
	end

	if self:needToLoseHp(self.player, nil, nil, nil, true) then return end

	if lord and self:isFriend(lord) and lord:getHp() <= 2 and self:isWeak(lord) then
		if self.player:isLord() then
			use.card = card
			return
		end
		if self:getCardsNum("Peach") > 1 and self:getCardsNum("Peach") + self:getCardsNum("Jink") > self.player:getMaxCards() then
			use.card = card
			return
		end
	end

	self:sort(self.friends, "hp")
	if self.friends[1]:objectName()==self.player:objectName() or self.player:getHp()<2 then
		use.card = card
		return
	end

	if #self.friends > 1 and
	(
	(not hasBuquEffect(self.friends[2]) and self.friends[2]:getHp() < 3 and self:getOverflow() < 2 and self.player:getMaxCards() > 2)	--這裡 "self.player:getMaxCards() > 2" 減少AI 2血棄桃(棄桃前手中2桃1閃)
	or (not hasBuquEffect(self.friends[1]) and self.friends[1]:getHp() < 2 and peaches <= 1 and self:getOverflow() < 3)
	) then
		return
	end

	if self.player:hasSkill("jieyin") and self:getOverflow() > 0 and not self.player:hasUsed("JieyinCard") then
		self:sort(self.friends, "hp")
		for _, friend in ipairs(self.friends) do
			if friend:isWounded() and friend:isMale() then return end
		end
	end

	if self.player:hasSkill("ganlu") and not self.player:hasUsed("GanluCard") then
		local dummy_use = {isDummy = true}
		self:useSkillCard(sgs.Card_Parse("@GanluCard=."),dummy_use)
		if dummy_use.card then return end
	end

	use.card = card
end

sgs.ai_card_intention.Peach = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		if to:hasSkill("wuhun") then continue end
		if not sgs.isRolePredictable() and from:objectName() ~= to:objectName()
			and sgs.current_mode_players["renegade"] > 0 and sgs.evaluatePlayerRole(to) == "rebel"
			and (sgs.evaluatePlayerRole(from) == "loyalist" or sgs.evaluatePlayerRole(from) == "renegade") then
			sgs.outputRoleValues(from, 100)
			sgs.role_evaluation[from:objectName()]["renegade"] = sgs.role_evaluation[from:objectName()]["renegade"] + 100
			sgs.outputRoleValues(from, 100)
		end
		sgs.updateIntention(from, to, -120)
	end
end

sgs.ai_use_value.Peach = 6
sgs.ai_keep_value.Peach = 7
sgs.ai_use_priority.Peach = 0.9

sgs.ai_use_value.Jink = 8.9
sgs.ai_keep_value.Jink = 5.2

sgs.dynamic_value.benefit.Peach = true

sgs.ai_keep_value.Weapon = 2.08
sgs.ai_keep_value.Armor = 2.06
sgs.ai_keep_value.Horse = 2.04

sgs.weapon_range.Weapon = 1
sgs.weapon_range.Crossbow = 1
sgs.weapon_range.DoubleSword = 2
sgs.weapon_range.QinggangSword = 2
sgs.weapon_range.IceSword = 2
sgs.weapon_range.GudingBlade = 2
sgs.weapon_range.Xueniangaogun = 2
sgs.weapon_range.Axe = 3
sgs.weapon_range.Blade = 3
sgs.weapon_range.Spear = 3
sgs.weapon_range.Halberd = 4
sgs.weapon_range.KylinBow = 5

sgs.ai_skill_invoke.double_sword = function(self, data)
	return not self:needKongcheng(self.player, true)
end

function sgs.ai_slash_weaponfilter.double_sword(self, to, player)
	return player:distanceTo(to) <= math.max(sgs.weapon_range.DoubleSword, player:getAttackRange()) and player:getGender() ~= to:getGender()
end

function sgs.ai_weapon_value.double_sword(self, enemy, player)
	if enemy and enemy:isMale() ~= player:isMale() then return 4 end
end

function SmartAI:getExpectedJinkNum(use)
	local jink_list = use.from:getTag("Jink_" .. use.card:toString()):toStringList()
	local index, jink_num = 1, 1
	for _, p in sgs.qlist(use.to) do
		if p:objectName() == self.player:objectName() then
			local n = tonumber(jink_list[index])
			if n == 0 then return 0
			elseif n > jink_num then jink_num = n end
		end
		index = index + 1
	end
	return jink_num
end

sgs.ai_skill_cardask["double-sword-card"] = function(self, data, pattern, target)
	if self.player:isKongcheng() then return "." end
	local use = data:toCardUse()
	local jink_num = self:getExpectedJinkNum(use)
	if jink_num > 1 and self:getCardsNum("Jink") == jink_num then return "." end

	if self:needKongcheng(self.player, true) and self.player:getHandcardNum() <= 2 then
		if self.player:getHandcardNum() == 1 then
			local card = self.player:getHandcards():first()
			return (jink_num > 0 and isCard("Jink", card, self.player)) and "." or ("$" .. card:getEffectiveId())
		end
		if self.player:getHandcardNum() == 2 then
			local first = self.player:getHandcards():first()
			local last = self.player:getHandcards():last()
			local jink = isCard("Jink", first, self.player) and first or (isCard("Jink", last, self.player) and last)
			if jink then
				return first:getEffectiveId() == jink:getEffectiveId() and ("$"..last:getEffectiveId()) or ("$"..first:getEffectiveId())
			end
		end
	end
	if target and self:isFriend(target) then return "." end
	if self:needBear() then return "." end
	if target and self:needKongcheng(target, true) then return "." end
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if (card:isKindOf("Slash") and self:getCardsNum("Slash") > 1)
			or (card:isKindOf("Jink") and self:getCardsNum("Jink") > 2)
			or card:isKindOf("Disaster")
			or (card:isKindOf("EquipCard") and not self:hasSkills(sgs.lose_equip_skill))
			or (not self.player:hasSkills("nosjizhi|jizhi") and (card:isKindOf("Collateral") or card:isKindOf("GodSalvation")
															or card:isKindOf("FireAttack") or card:isKindOf("IronChain") or card:isKindOf("AmazingGrace"))) then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

function sgs.ai_weapon_value.qinggang_sword(self, enemy)
	if enemy and enemy:getArmor() and enemy:hasArmorEffect(enemy:getArmor():objectName()) then return 3 end
end

function sgs.ai_slash_weaponfilter.qinggang_sword(self, enemy, player)
	if player:distanceTo(enemy) > math.max(sgs.weapon_range.QinggangSword, player:getAttackRange()) then return end
	if enemy:getArmor() and enemy:hasArmorEffect(enemy:getArmor():objectName())
		and (sgs.card_lack[enemy:objectName()] == 1 or getCardsNum("Jink", enemy, self.player) < 1) then
		return true
	end
end

sgs.ai_skill_invoke.ice_sword = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then
		if self:getDamagedEffects(target, self.player, true) or self:needToLoseHp(target, self.player, true) then return false
		elseif target:isChained() and self:isGoodChainTarget(target, self.player, nil, nil, damage.card) then return false
		elseif self:isWeak(target) or damage.damage > 1 then return true
		elseif target:getLostHp() < 1 then return false end
		return true
	else
		if self:isWeak(target) then return false end
		if damage.damage > 1 or self:hasHeavySlashDamage(self.player, damage.card, target) then return false end
		if target:hasSkill("lirang") and #self:getFriendsNoself(target) > 0 then return false end
		if target:getArmor() and self:evaluateArmor(target:getArmor(), target) > 3 and not (target:hasArmorEffect("silver_lion") and target:isWounded()) then return true end
		local num = target:getHandcardNum()
		if self.player:hasSkill("tieji") or self:canLiegong(target, self.player) then return false end
		if target:hasSkills("tuntian+zaoxian") and target:getPhase() == sgs.Player_NotActive then return false end
		if self:hasSkills(sgs.need_kongcheng, target) then return false end
		if target:getCards("he"):length()<4 and target:getCards("he"):length()>1 then return true end
		return false
	end
end

function sgs.ai_slash_weaponfilter.guding_blade(self, to)
	return to:isKongcheng() and not to:hasArmorEffect("silver_lion")
end

function sgs.ai_weapon_value.guding_blade(self, enemy)
	if not enemy then return end
	local value = 2
	if not enemy:hasArmorEffect("silver_lion") then
		if enemy:getHandcardNum() == 0 or (enemy:getHandcardNum() <= 1 and self.player:hasSkills("libeng")) then
			value = 4.5
		end
	end
	return value
end

function SmartAI:needToThrowAll(player)
	player = player or self.player
	if player:hasSkill("conghui") then return false end
	if not player:hasSkill("yongsi") then return false end
	if player:getPhase() == sgs.Player_NotActive or player:getPhase() == sgs.Player_Finish then return false end
	local zhanglu = self.room:findPlayerBySkillName("xiliang")
	if zhanglu and self:isFriend(zhanglu, player) then return false end
	local erzhang = self.room:findPlayerBySkillName("guzheng")
	if erzhang and not zhanglu and self:isFriend(erzhang, player) then return false end

	self.yongsi_discard = nil
	local index = 0

	local kingdom_num = 0
	local kingdoms = {}
	for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
		if not kingdoms[ap:getKingdom()] then
			kingdoms[ap:getKingdom()] = true
			kingdom_num = kingdom_num + 1
		end
	end

	local cards = self.player:getCards("he")
	local Discards = {}
	for _, card in sgs.qlist(cards) do
		local shouldDiscard = true
		if card:isKindOf("Axe") then shouldDiscard = false end
		if isCard("Peach", card, player) or isCard("Slash", card, player) then
			local dummy_use = { isDummy = true }
			self:useBasicCard(card, dummy_use)
			if dummy_use.card then shouldDiscard = false end
		end
		if card:getTypeId() == sgs.Card_TypeTrick then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then shouldDiscard = false end
		end
		if shouldDiscard then
			if #Discards < 2 then table.insert(Discards, card:getId()) end
			index = index + 1
		end
	end

	if #Discards == 2 and index < kingdom_num then
		self.yongsi_discard = Discards
		return true
	end
	return false
end

sgs.ai_skill_cardask["@axe"] = function(self, data, pattern, target)
	if target and self:isFriend(target) then return "." end
	local effect = data:toSlashEffect()
	local allcards = self.player:getCards("he")
	allcards = sgs.QList2Table(allcards)
	if self:hasHeavySlashDamage(self.player, effect.slash, target)
	  or (#allcards - 3 >= self.player:getHp())
	  or (self.player:hasSkill("kuanggu") and self.player:isWounded() and self.player:distanceTo(effect.to) == 1)
	  or (effect.to:getHp() == 1 and not effect.to:hasSkill("buqu"))
	  or (self:needKongcheng() and self.player:getHandcardNum() > 0)
	  or (self:hasSkills(sgs.lose_equip_skill, self.player) and self.player:getEquips():length() > 1 and self.player:getHandcardNum() < 2)
	  or self:needToThrowAll() then
		local discard = self.yongsi_discard
		if discard then return "$"..table.concat(discard, "+") end

		local hcards = {}
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if not (isCard("Slash", c, self.player) and self:hasCrossbowEffect()) then table.insert(hcards, c) end
		end
		self:sortByKeepValue(hcards)
		local cards = {}
		local hand, armor, def, off = 0, 0, 0, 0
		if self:needToThrowArmor() then
			table.insert(cards, self.player:getArmor():getEffectiveId())
			armor = 1
		end
		if (self:hasSkills(sgs.need_kongcheng) or not self:hasLoseHandcardEffective()) and self.player:getHandcardNum() > 0 then
			hand = 1
			for _, card in ipairs(hcards) do
				table.insert(cards, card:getEffectiveId())
				if #cards == 2 then break end
			end
		end
		if #cards < 2 and self:hasSkills(sgs.lose_equip_skill, self.player) then
			if #cards < 2 and self.player:getOffensiveHorse() then
				off = 1
				table.insert(cards, self.player:getOffensiveHorse():getEffectiveId())
			end
			if #cards < 2 and self.player:getArmor() then
				armor = 1
				table.insert(cards, self.player:getArmor():getEffectiveId())
			end
			if #cards < 2 and self.player:getDefensiveHorse() then
				def = 1
				table.insert(cards, self.player:getDefensiveHorse():getEffectiveId())
			end
		end

		if #cards < 2 and hand < 1 and self.player:getHandcardNum() > 2 then
			hand = 1
			for _, card in ipairs(hcards) do
				table.insert(cards, card:getEffectiveId())
				if #cards == 2 then break end
			end
		end

		if #cards < 2 and off < 1 and self.player:getOffensiveHorse() then
			off = 1
			table.insert(cards, self.player:getOffensiveHorse():getEffectiveId())
		end
		if #cards < 2 and hand < 1 and self.player:getHandcardNum() > 0 then
			hand = 1
			for _, card in ipairs(hcards) do
				table.insert(cards, card:getEffectiveId())
				if #cards == 2 then break end
			end
		end
		if #cards < 2 and armor < 1 and self.player:getArmor() then
			armor = 1
			table.insert(cards, self.player:getArmor():getEffectiveId())
		end
		if #cards < 2 and def < 1 and self.player:getDefensiveHorse() then
			def = 1
			table.insert(cards, self.player:getDefensiveHorse():getEffectiveId())
		end

		if #cards == 2 then
			local num = 0
			for _, id in ipairs(cards) do
				if self.player:hasEquip(sgs.Sanguosha:getCard(id)) then num = num + 1 end
			end
			self.equipsToDec = num
			local eff = self:damageIsEffective(effect.to, effect.nature, self.player, effect.slash)
			self.equipsToDec = 0
			if not eff then return "." end
			return "$" .. table.concat(cards, "+")
		end
	end
end


function sgs.ai_slash_weaponfilter.axe(self, to, player)
	return player:distanceTo(to) <= math.max(sgs.weapon_range.Axe, player:getAttackRange()) and self:getOverflow(player) > 0
end

function sgs.ai_weapon_value.axe(self, enemy, player)
	if player:hasSkills("jiushi|jiuchi|luoyi|pojun") then return 6 end
	if enemy and self:getOverflow() > 0 then return 3.1 end
	if enemy and enemy:getHp() < 3 then return 3 - enemy:getHp() end
end

sgs.ai_skill_cardask["blade-slash"] = function(self, data, pattern, target)
	if target and self:isFriend(target) and not self:findLeijiTarget(target, 50, self.player) then
		return "."
	end
	for _, slash in ipairs(self:getCards("Slash")) do
		if self:slashIsEffective(slash, target) and (self:isWeak(target) or self:getOverflow() > 0) then
			return slash:toString()
		end
	end
	return "."
end

function sgs.ai_weapon_value.blade(self, enemy)
	if not enemy and not self.player:hasWeapon("axe") then return math.min(self:getCardsNum("Slash"), 3) end
end

function cardsView_spear(self, player, skill_name)
	local cards = player:getCards("he")
	cards = sgs.QList2Table(cards)
	if (skill_name ~= "fuhun" and skill_name ~= "mingguang") or player:hasSkill("wusheng") then
		for _, acard in ipairs(cards) do
			if isCard("Slash", acard, player) then return end
		end
	end
	local cards = player:getCards("h")
	if skill_name == "mingguang" then
		cards = player:getCards("he")
	end
	cards = sgs.QList2Table(cards)
	local newcards = {}
	for _, card in ipairs(cards) do
		if not isCard("Slash", card, player) and not isCard("Peach", card, player) and not (isCard("ExNihilo", card, player) and player:getPhase() == sgs.Player_Play) then table.insert(newcards, card) end
	end
	if #newcards < 2 then return end
	sgs.ais[player:objectName()]:sortByKeepValue(newcards)

	local card_id1 = newcards[1]:getEffectiveId()
	local card_id2 = newcards[2]:getEffectiveId()

	local card_str = ("slash:%s[%s:%s]=%d+%d"):format(skill_name, "to_be_decided", 0, card_id1, card_id2)
	return card_str
end

function sgs.ai_cardsview.spear(self, class_name, player)
	if class_name == "Slash" then
		return cardsView_spear(self, player, "spear")
	end
end

function turnUse_spear(self, inclusive, skill_name)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if (skill_name ~= "fuhun" and skill_name ~= "mingguang") or self.player:hasSkill("wusheng") then
		for _, acard in ipairs(cards) do
			if isCard("Slash", acard, self.player) then return end
		end
	end

	local cards = self.player:getCards("h")
	if skill_name == "mingguang" then
		cards = self.player:getCards("he")
	end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	local newcards = {}
	for _, card in ipairs(cards) do
		if not isCard("Slash", card, self.player) and not isCard("Peach", card, self.player)
		and not (isCard("ExNihilo", card, self.player) and self.player:getPhase() == sgs.Player_Play)
		and not (self.player:hasSkill("jianchu") and isCard("Jink", card, self.player))
			then table.insert(newcards, card)
		end
	end
	if #cards <= self.player:getHp() - 1 and self.player:getHp() <= 4 and not self:hasHeavySlashDamage(self.player)
		and not self:hasSkills("kongcheng|lianying|noslianying|paoxiao|shangshi|noshangshi|zhiji|benghuai|xingxiong|hengxin|liucai") then return end
	if #newcards < 2 then return end

	local card_id1 = newcards[1]:getEffectiveId()
	local card_id2 = newcards[2]:getEffectiveId()

	if newcards[1]:isBlack() and newcards[2]:isBlack() then
		local black_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack)
		local nosuit_slash = sgs.Sanguosha:cloneCard("slash")

		self:sort(self.enemies, "defenseSlash")
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and not self:slashProhibit(nosuit_slash, enemy) and self:slashIsEffective(nosuit_slash, enemy)
				and self:canAttack(enemy) and self:slashProhibit(black_slash, enemy) and self:isWeak(enemy) then
				local redcards, blackcards = {}, {}
				for _, acard in ipairs(newcards) do
					if acard:isBlack() then table.insert(blackcards, acard) else table.insert(redcards, acard) end
				end
				if #redcards == 0 then break end

				local redcard, othercard

				self:sortByUseValue(blackcards, true)
				self:sortByUseValue(redcards, true)
				redcard = redcards[1]

				othercard = #blackcards > 0 and blackcards[1] or redcards[2]
				if redcard and othercard then
					card_id1 = redcard:getEffectiveId()
					card_id2 = othercard:getEffectiveId()
					break
				end
			end
		end
		black_slash:deleteLater()
		nosuit_slash:deleteLater()
	end

	local card_str = ("slash:%s[%s:%s]=%d+%d"):format(skill_name, "to_be_decided", 0, card_id1, card_id2)
	local slash = sgs.Card_Parse(card_str)
	return slash
end

local Spear_skill = {}
Spear_skill.name = "spear"
table.insert(sgs.ai_skills, Spear_skill)
Spear_skill.getTurnUseCard = function(self, inclusive)
	return turnUse_spear(self, inclusive, "spear")
end

function sgs.ai_weapon_value.spear(self, enemy, player)
	if player:hasSkills("paoxiao|xingxiong") and player:getHandcardNum() > 2 then
		return (player:getHandcardNum() - self:getCardsNum("Slash"))/2
	end
	if enemy and getCardsNum("Slash", player, self.player) == 0 then
		if self:getOverflow(player) > 0 then return 2
		elseif player:getHandcardNum() > 2 then return 1
		end
	end
	return 0
end

function sgs.ai_slash_weaponfilter.fan(self, to, player)
	return player:distanceTo(to) <= math.max(sgs.weapon_range.Fan, player:getAttackRange())
		and (to:hasArmorEffect("vine") or to:hasArmorEffect("toujing"))
end

sgs.ai_skill_invoke.kylin_bow = function(self, data)
	local damage = data:toDamage()
	if damage.from:hasSkill("kuangfu") and damage.to:getCards("e"):length() == 1 then return false end
	if self:hasSkills(sgs.lose_equip_skill, damage.to) then
		return self:isFriend(damage.to)
	end
	return self:isEnemy(damage.to)
end

function sgs.ai_slash_weaponfilter.kylin_bow(self, to, player)
	return player:distanceTo(to) <= math.max(sgs.weapon_range.KylinBow, player:getAttackRange())
		and (to:getDefensiveHorse() or to:getOffensiveHorse())
end

function sgs.ai_weapon_value.kylin_bow(self, enemy)
	if enemy and (enemy:getOffensiveHorse() or enemy:getDefensiveHorse()) then return 1 end
end

sgs.ai_skill_invoke.eight_diagram = function(self, data)
	local dying = 0
	local handang = self.room:findPlayerBySkillName("nosjiefan")
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:getHp() < 1 and not aplayer:hasSkill("nosbuqu") then dying = 1 break end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end

	local heart_jink = false
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:getSuit() == sgs.Card_Heart and isCard("Jink", card, self.player) then
			heart_jink = true
			break
		end
	end
	
	--隊友要鐵鎖連環殺自己時不用八卦陣
	local current = self.room:getCurrent()
	if current and self:isFriend(current) and self.player:isChained() and self:isGoodChainTarget(self.player, current) then return false end	--內奸跳反會有問題，非屬性殺也有問題。但狀況特殊，八卦陣原碼資訊不足，暫時這樣寫。
--	slash = sgs.Sanguosha:cloneCard("fire_slash")
--	if slash and slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, self.room:getCurrent(), nil, nil, slash) then return false end

	if self:hasSkills("tiandu|leiji|nosleiji|olleiji|gushou|xiaoan") then
		if self.player:hasFlag("dahe") and not heart_jink then return true end
		if sgs.hujiasource and not self:isFriend(sgs.hujiasource) and (sgs.hujiasource:hasFlag("dahe") or self.player:hasFlag("dahe")) then return true end
		if sgs.lianlisource and not self:isFriend(sgs.lianlisource) and (sgs.lianlisource:hasFlag("dahe") or self.player:hasFlag("dahe")) then return true end
		if self.player:hasFlag("dahe") and handang and self:isFriend(handang) and dying > 0 then return true end
	end
	if self.player:getHandcardNum() == 1 and self:getCardsNum("Jink") == 1 and self.player:hasSkills("zhiji|beifa") and self:needKongcheng() then
		local enemy_num = self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player)
		if self.player:getHp() > enemy_num and enemy_num <= 1 then return false end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end
	if self.player:hasFlag("dahe") then return false end
	if sgs.hujiasource and (not self:isFriend(sgs.hujiasource) or sgs.hujiasource:hasFlag("dahe")) then return false end
	if sgs.lianlisource and (not self:isFriend(sgs.lianlisource) or sgs.lianlisource:hasFlag("dahe")) then return false end
	if self:getDamagedEffects(self.player, nil, true) or self:needToLoseHp(self.player, nil, true, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end
	local zhangjiao = self.room:findPlayerBySkillName("guidao")
	if zhangjiao and self:isEnemy(zhangjiao) then
		if getKnownCard(zhangjiao, self.player, "black", false, "he") > 1 then return false end
		if self:getCardsNum("Jink") > 1 and getKnownCard(zhangjiao, self.player, "black", false, "he") > 0 then return false end
	end
	
	local has_enemy_zhangbao = false
	local has_ol_zhangbao = false
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasSkill("zhoufu") and self:isEnemy(p) then
			has_enemy_zhangbao = true
		end
		if p:hasSkill("ol_zhoufu") then
			has_ol_zhangbao = true
		end
	end
	if has_enemy_zhangbao and self.player:getPile("incantation"):length() > 0
	and sgs.Sanguosha:getCard(self.player:getPile("incantation"):first()):isBlack()
	then
		return false
	end
	if has_ol_zhangbao and self.player:getPile("incantation"):length() > 0 then return false end
	--if self:getCardsNum("Jink") > 0 and self.player:getPile("incantation"):length() > 0 then return false end
	return true
end

function sgs.ai_armor_value.eight_diagram(player, self)
	local haszj = self:hasSkills("guidao", self:getEnemies(player))
	if haszj then
		return 2
	end
	if player:hasSkills("tiandu|leiji|nosleiji|olleiji|noszhenlie|gushou|xiaoan") then
		return 6
	end

	if self.role == "loyalist" and self.player:getKingdom()=="wei" and not self.player:hasSkills("bazhen|linglong|xiangrui") and getLord(self.player) and getLord(self.player):hasLordSkill("hujia") then
		return 5
	end

	return 4
end

function sgs.ai_armor_value.renwang_shield(player, self)
	if player:hasSkills("yizhong|bingshen") then return 0 end
	if player:hasSkills("bazhen|linglong|xiangrui|fuyin") then return 0 end
	if player:hasSkills("leiji|nosleiji|olleiji") and getKnownCard(player, self.player, "Jink", true) > 1 and player:hasSkill("guidao")
		and getKnownCard(player, self.player, "black", false, "he") > 0 then
			return 0
	end
	if player:hasSkills("xiaoan") and getKnownCard(player, self.player, "Jink", true) > 1 then
			return 0
	end
	return 4.5
end

function sgs.ai_armor_value.silver_lion(player, self)
	if self:hasWizard(self:getEnemies(player), true) then
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if player:containsTrick("lightning") then return 5 end
		end
	end
	if self.player:isWounded() and not self.player:getArmor() then return 9 end
	if self.player:isWounded() and self:getCardsNum("Armor", "h") >= 2 and not self.player:hasArmorEffect("silver_lion") then return 8 end
	return 1
end

function sgs.ai_armor_value.xuanwujia(player, self)	--玄武甲价值
	if player:hasSkills("yizhong|bingshen") then return 0 end
	if player:hasSkills("bazhen|linglong|xiangrui|fuyin") then return 0 end
	if (player:getWeapon() and player:getWeapon():isKindOf("Xueniangaogun")) or player:hasSkills("jingxin|xianzhi") then
		return 6
	end

	return 3.6
end

function sgs.ai_armor_value.neneko(player, self)	--猫玩偶价值
	if player:hasSkills("yizhong|bingshen") then return 0 end
	if player:hasSkills("bazhen|linglong|xiangrui|fuyin") then return 0 end
	if player:getHp() >= 2 then return 4.5 end
	return 2
end

function sgs.ai_weapon_value.xueniangaogun(self, enemy, player)	--雪年糕棍价值
	if player:getArmor() and player:getArmor():isKindOf("Xuanwujia") then return 5 end
	return 1
end

sgs.ai_use_priority.OffensiveHorse = 2.69

sgs.ai_use_priority.Axe = 2.688
sgs.ai_use_priority.Halberd = 2.685
sgs.ai_use_priority.KylinBow = 2.68
sgs.ai_use_priority.Blade = 2.675
sgs.ai_use_priority.GudingBlade = 2.67
sgs.ai_use_priority.DoubleSword =2.665
sgs.ai_use_priority.Spear = 2.66
-- sgs.ai_use_priority.Fan = 2.655
sgs.ai_use_priority.IceSword = 2.65
sgs.ai_use_priority.Xueniangaogun = 2.655
sgs.ai_use_priority.QinggangSword = 2.645
sgs.ai_use_priority.Crossbow = 2.63

sgs.ai_use_priority.SilverLion = 1.0
-- sgs.ai_use_priority.Vine = 0.95
sgs.ai_use_priority.Xuanwujia = 0.79
sgs.ai_use_priority.EightDiagram = 0.8
sgs.ai_use_priority.RenwangShield = 0.85
sgs.ai_use_priority.DefensiveHorse = 2.75

sgs.dynamic_value.damage_card.ArcheryAttack = true
sgs.dynamic_value.damage_card.SavageAssault = true

sgs.ai_use_value.ArcheryAttack = 3.8
sgs.ai_use_priority.ArcheryAttack = 3.5
sgs.ai_keep_value.ArcheryAttack = 3.38
sgs.ai_use_value.SavageAssault = 3.9
sgs.ai_use_priority.SavageAssault = 3.5
sgs.ai_keep_value.SavageAssault = 3.36

function SmartAI:hasSlashAttackSkill(from)	--有菜刀技能(使用杀加成，不包括转化杀)
	from = from or self.player
	return from:hasSkills("libeng|zhulie|hunyin|xingyao|xingxiong|huweishan|bianpin|santan|jvhe|keke|juediao|yaoji")
end

function SmartAI:hasSlashCostSkill(from)	--有需要消耗杀的技能（该角色不易获得杀）
	from = from or self.player
	return from:hasSkills("zhige_gugu")
end

function SmartAI:needNotResponseSlash()
	if not self:isWeak() then
		if self.player:hasSkills("luabixian") then
			return true
		end
		if (self:hasSlashAttackSkill() or self:hasSlashCostSkill()) and getCardsNum("Slash", self.player, self.player) == 1 then
			return true
		end
	end
end

sgs.ai_skill_cardask.aoe = function(self, data, pattern, target, name)
	if self.room:getMode():find("_mini_35") and self.player:getLostHp() == 1 and name == "archery_attack" then return "." end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end

	local aoe
	local is_clone_card = false
	if type(data) == "userdata" then aoe = data:toCardEffect().card else aoe = sgs.Sanguosha:cloneCard(name) is_clone_card = true end
	assert(aoe ~= nil)
	
	local function before_return()
		if is_clone_card then
			aoe:deleteLater()
		end
	end
	
	local menghuo = self.room:findPlayerBySkillName("huoshou")
	local attacker = target
	if menghuo and aoe:isKindOf("SavageAssault") then attacker = menghuo end

	--if not self:damageIsEffective(nil, nil, attacker, aoe) then before_return() return "." end
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, attacker, aoe) then before_return() return "." end
	if self:getDamagedEffects(self.player, attacker) or self:needToLoseHp(self.player, attacker) then before_return() return "." end

	--排除司馬徽隱士技能，AI司馬徽被打
	if target and self.player:hasSkill("yinshi") and not target:hasSkill("jueqing") and self.player:getMark("@dragon") + self.player:getMark("@phoenix") == 0 and not self.player:getArmor() then before_return() return "." end
	--排除TW馬良白眉，TW馬良被打
	if target and self.player:hasSkill("twyj_baimei") and not target:hasSkill("jueqing") and self.player:isKongcheng() then before_return() return "." end
	--排除響應制蠻隊友使用AOE傷害錦囊牌
	if target and self:isFriend(target) and not target:hasSkill("jueqing") and target:hasSkills("zhiman|bf_zhiman|lua_zhiman") then before_return() return "." end
	--杜畿安東不響應AOE
	if target and self:isFriend(target) and not target:hasSkill("jueqing") and self.player:hasSkill("andong") and sgs.ai_role[self.player:objectName()] ~= "neutral" then before_return() return "." end
	--司馬昭怠攻不響應AOE
	if target and self:isFriend(target) and not target:hasSkill("jueqing") and self.player:hasSkill("daigong") and sgs.ai_role[self.player:objectName()] ~= "neutral" then before_return() return "." end
	--新神趙雲手中有酒或桃賣血摸牌
	if self.player:hasSkills("new_longhun+new_juejing") and not self:hasHeavySlashDamage(target, nil, self.player) then
		if self:getCardId("Peach") or self:getCardId("Analeptic") then
			before_return() return "."
		end
	end

	if self.player:hasSkill("wuyan") and not attacker:hasSkill("jueqing") then before_return() return "." end
	if attacker:hasSkill("wuyan") and not attacker:hasSkill("jueqing") then before_return() return "." end
	if self.player:getMark("@fenyong") > 0 and not attacker:hasSkill("jueqing") then before_return() return "." end

	if not attacker:hasSkill("jueqing") and self.player:hasSkills("jianxiong|nitai") and (self.player:getHp() > 1 or self:getAllPeachNum() > 0)
		and not self:willSkipPlayPhase() then
		if not self:needKongcheng(self.player, true) and self:getAoeValue(aoe) > -10 then before_return() return "." end
		if sgs.ai_qice_data then
			local damagecard = sgs.ai_qice_data:toCardUse().card
			if damagecard:subcardsLength() > 2 then self.jianxiong = true before_return() return "." end
			for _, id in sgs.qlist(damagecard:getSubcards()) do
				local card = sgs.Sanguosha:getCard(id)
				if not self:needKongcheng(self.player, true) and isCard("Peach", card, self.player) then before_return() return "." end
			end
		end
	end

	local current = self.room:getCurrent()
	if current and current:hasSkill("juece") and self:isEnemy(current) and self.player:getHp() > 0 then
		local classname = (name == "savage_assault" and "Slash" or "Jink")
		local use = false
		for _, card in ipairs(self:getCards(classname)) do
			if not self.player:isLastHandCard(card, true) then
				if not (self:needNotResponseSlash() and name == "savage_assault") then
					use = true
					break
				end
			end
		end
		if not use then before_return() return "." end
	end
end

sgs.ai_skill_cardask["savage-assault-slash"] = function(self, data, pattern, target)
	return sgs.ai_skill_cardask.aoe(self, data, pattern, target, "savage_assault")
end

sgs.ai_skill_cardask["archery-attack-jink"] = function(self, data, pattern, target)
	return sgs.ai_skill_cardask.aoe(self, data, pattern, target, "archery_attack")
end

sgs.ai_keep_value.Nullification = 3.8
sgs.ai_use_value.Nullification = 8

function SmartAI:useCardAmazingGrace(card, use)
	if self.player:hasSkill("noswuyan") then use.card = card return end
	if (self.role == "lord" or self.role == "loyalist") and sgs.turncount <= 2 and self.player:getSeat() <= 3 and self.player:aliveCount() > 5 then return end
	local value = 1
	local suf, coeff = 0.8, 0.8
	if self:needKongcheng() and self.player:getHandcardNum() == 1 or self.player:hasSkills("nosjizhi|jizhi") then
		suf = 0.6
		coeff = 0.6
	end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local index = 0
		if self:hasTrickEffective(card, player, self.player) then
			if self:isFriend(player) then index = 1 elseif self:isEnemy(player) then index = -1 end
		end
		value = value + index * suf
		if value < 0 then return end
		suf = suf * coeff
	end
	use.card = card
end

function SmartAI:willUseAmazingGrace(card)
	local use = sgs.CardUseStruct()
	self:useCardAmazingGrace(card, use)
	return use.card == card
end

sgs.ai_use_value.AmazingGrace = 3
sgs.ai_keep_value.AmazingGrace = -1
sgs.ai_use_priority.AmazingGrace = 1.2
sgs.dynamic_value.benefit.AmazingGrace = true

function SmartAI:willUseGodSalvation(card)
	if not card then self.room:writeToConsole(debug.traceback()) return false end
	local good, bad = 0, 0
	local wounded_friend = 0
	local wounded_enemy = 0

	local liuxie = self.room:findPlayerBySkillName("huangen")
	if liuxie then
		if self:isFriend(liuxie) then
			if self.player:hasSkill("noswuyan") and liuxie:getHp() > 0 then return true end
			good = good + 7 * liuxie:getHp()
		else
			if self.player:hasSkill("noswuyan") and self:isEnemy(liuxie) and liuxie:getHp() > 1 and #self.enemies > 1 then return false end
			bad = bad + 7 * liuxie:getHp()
		end
	end

	if self.player:hasSkill("noswuyan") and (self.player:isWounded() or self.player:hasSkills("nosjizhi|jizhi")) then return true end
	if self.player:hasSkill("noswuyan") then return false end

	if self.player:hasSkills("nosjizhi|jizhi") then good = good + 6 end
	if (self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1) or not self:hasLoseHandcardEffective() then good = good + 5 end

	for _, friend in ipairs(self.friends) do
		good = good + 10 * getCardsNum("Nullification", friend, self.player)
		if self:hasTrickEffective(card, friend, self.player) then
			if friend:isWounded() then
				wounded_friend = wounded_friend + 1
				good = good + 10
				if friend:isLord() then good = good + 10 / math.max(friend:getHp(), 1) end
				if self:hasSkills(sgs.masochism_skill, friend) then
					good = good + 5
				end
				if friend:getHp() <= 1 and self:isWeak(friend) then
					good = good + 5
					if friend:isLord() then good = good + 10 end
				else
					if friend:isLord() then good = good + 5 end
				end
				if self:needToLoseHp(friend, nil, nil, true, true) then good = good - 3 end
			elseif friend:hasSkills("danlao|sheyan|buen") then good = good + 5
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		bad = bad + 10 * getCardsNum("Nullification", enemy, self.player)
		if self:hasTrickEffective(card, enemy, self.player) then
			if enemy:isWounded() then
				wounded_enemy = wounded_enemy + 1
				bad = bad + 10
				if enemy:isLord() then
					bad = bad + 10 / math.max(enemy:getHp(), 1)
				end
				if self:hasSkills(sgs.masochism_skill, enemy) then
					bad = bad + 5
				end
				if enemy:getHp() <= 1 and self:isWeak(enemy) then
					bad = bad + 5
					if enemy:isLord() then bad = bad + 10 end
				else
					if enemy:isLord() then bad = bad + 5 end
				end
				if self:needToLoseHp(enemy, nil, nil, true, true) then bad = bad - 3 end
			elseif enemy:hasSkill("danlao") then bad = bad + 5
			end
		end
	end
	return (good - bad > 5 and wounded_friend > 0)  or (wounded_friend == 0 and wounded_enemy == 0 and self.player:hasSkills("nosjizhi|jizhi"))
end

function SmartAI:useCardGodSalvation(card, use)
	if self:willUseGodSalvation(card) then
		use.card = card
	end
end

sgs.ai_use_priority.GodSalvation = 1.1
sgs.ai_keep_value.GodSalvation = 3.32
sgs.dynamic_value.benefit.GodSalvation = true
sgs.ai_card_intention.GodSalvation = function(self, card, from, tos)
	local can, first
	for _, to in ipairs(tos) do
		if to:isWounded() and not first then
			first = to
			can = true
		elseif first and to:isWounded() and not self:isFriend(first, to) then
			can = false
			break
		end
	end
	if can then
		sgs.updateIntention(from, first, -10)
	end
end

function SmartAI:JijiangSlash(player)
	if not player then self.room:writeToConsole(debug.traceback()) return 0 end
	if not player:hasLordSkill("jijiang") then return 0 end
	local slashs = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		local slash_num = getCardsNum("Slash", p, self.player)
		if p:getKingdom() == "shu" and slash_num >= 1 and sgs.card_lack[p:objectName()]["Slash"] ~= 1 and
			(sgs.turncount <= 1 and sgs.ai_role[p:objectName()] == "neutral" or self:isFriend(player, p)) then
				slashs = slashs + slash_num
		end
	end
	return slashs
end

function SmartAI:useCardDuel(duel, use)
	if self.player:hasSkill("wuyan") and not self.player:hasSkill("jueqing") then return end
	if self.player:hasSkill("noswuyan") then return end

	local enemies = self:exclude(self.enemies, duel)
	local friends = self:exclude(self.friends_noself, duel)
	duel:setFlags("AI_Using")
	local n1 = self:getCardsNum("Slash")
	duel:setFlags("-AI_Using")
	if self.player:hasSkill("wushuang") or use.isWuqian then	--double slash for duel
		n1 = n1 * 2
	end
	if self.player:hasSkill("santan") and self.player:getMark("santan_counter") == 2 then	--三叹不可响应
		n1 = 9999
	end
	local huatuo = self.room:findPlayerBySkillName("jijiu")
	local targets = {}

	local canUseDuelTo=function(target)
		return self:hasTrickEffective(duel, target) and self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player, duel) and not self.room:isProhibited(self.player, target, duel)
		--排除界曹操
		and not (target:hasSkills("jianxiong|nitai") and target:getHp() > 1 and not self.player:hasSkill("jueqing"))
		--排除神曹操
		and not (target:hasSkill("guixin") and target:getHp() > 1 and sgs.turncount <= 1 and not self.player:hasSkill("jueqing"))
	end

	for _, friend in ipairs(friends) do
		if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
			and friend:hasSkill("jieming") and canUseDuelTo(friend) and self.player:hasSkill("nosrende") and (huatuo and self:isFriend(huatuo)) then
			table.insert(targets, friend)
		end
	end

	for _, enemy in ipairs(enemies) do
		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName()))
			and self.player:hasFlag("duelTo_" .. enemy:objectName()) and canUseDuelTo(enemy) then
			table.insert(targets, enemy)
		end
	end

	local cmp = function(a, b)
		local v1 = getCardsNum("Slash", a) + a:getHp()
		local v2 = getCardsNum("Slash", b) + b:getHp()

		if a:isKongcheng() then v1 = v1 - 20 end
		if b:isKongcheng() then v2 = v2 - 20 end

		if self:getDamagedEffects(a, self.player) then v1 = v1 + 20 end
		if self:getDamagedEffects(b, self.player) then v2 = v2 + 20 end

		if not self:isWeak(a) and a:hasSkills("jianxiong|nitai") and not self.player:hasSkill("jueqing") then v1 = v1 + 10 end
		if not self:isWeak(b) and b:hasSkills("jianxiong|nitai") and not self.player:hasSkill("jueqing") then v2 = v2 + 10 end

		if self:needToLoseHp(a) then v1 = v1 + 5 end
		if self:needToLoseHp(b) then v2 = v2 + 5 end

		if self:hasSkills(sgs.masochism_skill, a) then v1 = v1 + 5 end
		if self:hasSkills(sgs.masochism_skill, b) then v2 = v2 + 5 end

		if not self:isWeak(a) and a:hasSkill("jiang") then v1 = v1 + 5 end
		if not self:isWeak(b) and b:hasSkill("jiang") then v2 = v2 + 5 end

		if a:hasLordSkill("jijiang") then v1 = v1 + self:JijiangSlash(a) * 2 end
		if b:hasLordSkill("jijiang") then v2 = v2 + self:JijiangSlash(b) * 2 end

		if v1 == v2 then return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self) end

		return v1 < v2
	end

	table.sort(enemies, cmp)

	for _, enemy in ipairs(enemies) do
		local useduel
		local n2 = getCardsNum("Slash", enemy)
		if enemy:hasSkill("wushuang") then n2 = n2 * 2 end
		if sgs.card_lack[enemy:objectName()]["Slash"] == 1 then n2 = 0 end
		if self.player:getPile("moci"):length() > 0 and self.player:getPile("moci"):length() > enemy:getHandcardNum() then n2 = 0 end	--魔刺不可响应
		useduel = n1 >= n2 or self:needToLoseHp(self.player, nil, nil, true)
					or self:getDamagedEffects(self.player, enemy) or (n2 < 1 and sgs.isGoodHp(self.player))
					or ((self:hasSkills("jianxiong|nitai") or self.player:getMark("shuangxiong") > 0) and sgs.isGoodHp(self.player))

		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName()))
			and self:objectiveLevel(enemy) > 3 and canUseDuelTo(enemy) and not self:cantbeHurt(enemy) and useduel and sgs.isGoodTarget(enemy, enemies, self) then
			if not table.contains(targets, enemy) then table.insert(targets, enemy) end
		end
	end

	if #targets > 0 then

		local godsalvation = self:getCard("GodSalvation")
		if godsalvation and godsalvation:getId() ~= duel:getId() and self:willUseGodSalvation(godsalvation) then
			local use_gs = true
			for _, p in ipairs(targets) do
				if not p:isWounded() or not self:hasTrickEffective(godsalvation, p, self.player) then break end
				use_gs = false
			end
			if use_gs then
				use.card = godsalvation
				return
			end
		end

		local targets_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, duel)
		if use.isDummy and use.xiechan then targets_num = 100 end
		if use.isDummy and use.extra_target then targets_num = targets_num + use.extra_target end
		local enemySlash = 0
		local setFlag = false
		local lx = self.room:findPlayerBySkillName("huangen")

		use.card = duel

		for i = 1, #targets, 1 do
			local n2 = getCardsNum("Slash", targets[i])
			if sgs.card_lack[targets[i]:objectName()]["Slash"] == 1 then n2 = 0 end
			if self.player:getPile("moci"):length() > 0 and self.player:getPile("moci"):length() > targets[i]:getHandcardNum() then n2 = 0 end	--魔刺不可响应
			if self:isEnemy(targets[i]) then enemySlash = enemySlash + n2 end

			if not use.isDummy and self.player:hasSkill("duyi") and targets[i]:getHp() == 1 and self.room:getDrawPile():length() > 0 and not self.player:hasUsed("DuyiCard") then
				sgs.ai_duyi = { id = self.room:getDrawPile():first(), tg = targets[i] }
				use.card = sgs.Card_Parse("@DuyiCard=.")
				if use.to then use.to = sgs.SPlayerList() end
				return
			end
			if use.to then
				local target
				if string.find(duel:getSkillName(), "zhanjue") then
					local hp = 999
					for _, enemy in ipairs(self.enemies) do
						local count = true
						for _, c in sgs.qlist(enemy:getHandcards()) do
							if c:isKindOf("Slash") then
								count = false
							end
						end
						if count then
							hp = math.min(hp, enemy:getHp())
						end
					end
					for _, enemy in ipairs(self.enemies) do
						if enemy:getHp() == hp and canUseDuelTo(enemy) then
							target = enemy
						end
					end
					if target == nil then
						for _, enemy in ipairs(self.enemies) do
							local count = 0
							for _, c in sgs.qlist(enemy:getHandcards()) do
								if c:isKindOf("Slash") then
									count = count + 1
								end
							end
							hp = math.min(hp, count)
						end
						for _, enemy in ipairs(self.enemies) do
							local count = 0
							for _, c in sgs.qlist(enemy:getHandcards()) do
								if c:isKindOf("Slash") then
									count = count + 1
								end
							end
							if count == hp and canUseDuelTo(enemy) then
								target = enemy
							end
						end
					end
					if target == nil then return end
				end
				if i == 1 and not use.current_targets then
					if not string.find(duel:getSkillName(), "zhanjue") or (target and targets[i]:objectName() == target) then
						use.to:append(targets[i])
					end
					if not use.isDummy and math.random() < 0.5 then self:speak("duel", self.player:isFemale()) end
				elseif n1 >= enemySlash and not targets[i]:hasSkill("danlao") and not (lx and self:isEnemy(lx) and lx:getHp() > targets_num / 2) then
					if not string.find(duel:getSkillName(), "zhanjue") or (target and targets[i]:objectName() == target) then
						use.to:append(targets[i])
					end
				end
				if not setFlag and self.player:getPhase() == sgs.Player_Play and self:isEnemy(targets[i]) and canUseDuelTo(targets[i]) then
					self.player:setFlags("duelTo" .. targets[i]:objectName())
					setFlag = true
				end
				if use.to:isEmpty() then use.to:append(target) end
				if use.to:length() == targets_num then return end
			end
		end
	end
end

sgs.ai_card_intention.Duel = function(self, card, from, tos)
	if string.find(card:getSkillName(), "lijian") then return end
	if string.find(card:getSkillName(), "m_lianjicard") then return end
	if string.find(card:getSkillName(), "xunxiao") then return end	--不记仇恨值
	sgs.updateIntentions(from, tos, 80)
end

sgs.ai_use_value.Duel = 3.7
sgs.ai_use_priority.Duel = 2.9
sgs.ai_keep_value.Duel = 3.42

sgs.dynamic_value.damage_card.Duel = true

sgs.ai_skill_cardask["duel-slash"] = function(self, data, pattern, target)
	if self.player:getPhase()==sgs.Player_Play then return self:getCardId("Slash") end

	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	
	--有大傷害全部殺都丟出去
	if self:hasHeavySlashDamage(target, nil, self.player) then return self:getCardId("Slash") end
	
	if self.player:hasFlag("AIGlobal_NeedToWake") and self.player:getHp() > 1 then return "." end
	if (target:hasSkill("wuyan") or self.player:hasSkill("wuyan")) and not target:hasSkill("jueqing") then return "." end
	if self.player:getMark("@fenyong") >0 and self.player:hasSkill("fenyong") and not target:hasSkill("jueqing") then return "." end
	if self.player:hasSkill("wuhun") and self:isEnemy(target) and target:isLord() and #self.friends_noself > 0 then return "." end

	--排除司馬徽隱士技能，AI司馬徽被打
	if target and self.player:hasSkill("yinshi") and not target:hasSkill("jueqing") and self.player:getMark("@dragon") + self.player:getMark("@phoenix") == 0 and not self.player:getArmor() then return "." end
	--排除TW馬良白眉，TW馬良被打
	if target and self.player:hasSkill("twyj_baimei") and not target:hasSkill("jueqing") and self.player:isKongcheng() then return "." end
	--新神趙雲手中有酒或桃賣血摸牌
	if self.player:hasSkills("new_longhun+new_juejing") and not self:hasHeavySlashDamage(target, nil, self.player) then
		if self:getCardId("Peach") or self:getCardId("Analeptic") then
			return "."
		end
	end

	if self:cantbeHurt(target) then return "." end

	if self:isFriend(target) and target:hasSkill("rende") and self.player:hasSkill("jieming") then return "." end
	if self:isEnemy(target) and not self:isWeak() and self:getDamagedEffects(self.player, target) then return "." end

	if self:isFriend(target) then
		if self:getDamagedEffects(self.player, target) or self:needToLoseHp(self.player, target) then return "." end
		if self:getDamagedEffects(target, self.player) or self:needToLoseHp(target, self.player) then
			return self:getCardId("Slash")
		else
			if target:isLord() and not sgs.isLordInDanger() and not sgs.isGoodHp(self.player) then return self:getCardId("Slash") end
			if self.player:isLord() and sgs.isLordInDanger() then return self:getCardId("Slash") end
			return "."
		end
	end

	if self:needNotResponseSlash() then return "." end

	if (not self:isFriend(target) and self:getCardsNum("Slash") >= getCardsNum("Slash", target, self.player))
		or (target:getHp() > 2 and self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and not self.player:hasSkill("buqu"))
		
		--薛綜復難技能有殺能出就出
		or (self.player:hasSkill("funan") and self.player:getMark("@funan") > 0)
		then
		return self:getCardId("Slash")
	else return "." end
end

function SmartAI:useCardExNihilo(card, use)
	local xiahou = self.room:findPlayerBySkillName("yanyu")
	if xiahou and self:isEnemy(xiahou) and xiahou:getMark("YanyuDiscard2") > 0 then return end

	use.card = card
	if not use.isDummy then
		self:speak("lucky")
	end
end

sgs.ai_card_intention.ExNihilo = -80
sgs.ai_keep_value.ExNihilo = 3.9
sgs.ai_use_value.ExNihilo = 10
sgs.ai_use_priority.ExNihilo = 9.3

sgs.dynamic_value.benefit.ExNihilo = true

function SmartAI:getDangerousCard(who)
	local weapon = who:getWeapon()
	local armor = who:getArmor()
	
	if who:getTreasure() and who:getTreasure():isKindOf("LongPheasantTailFeatherPurpleGoldCrown") then
		who:getTreasure():getEffectiveId()
	end
	
	if weapon and (weapon:isKindOf("Crossbow") or weapon:isKindOf("GudingBlade")) then
		for _, friend in ipairs(self.friends) do
			if weapon:isKindOf("Crossbow") and who:distanceTo(friend) <= 1 and (getCardsNum("Slash", who, self.player) > 0 or who:hasSkill("wuzang")) then
				return weapon:getEffectiveId()
			end
			if weapon:isKindOf("GudingBlade") and who:inMyAttackRange(friend) and friend:isKongcheng() and not friend:hasSkills("kongcheng|tianming") and getCardsNum("Slash", who) > 0 then
				return weapon:getEffectiveId()
			end
		end
	end
	if (weapon and weapon:isKindOf("Spear") and who:hasSkills("paoxiao|xingxiong") and who:getHandcardNum() >=1 ) then return weapon:getEffectiveId() end
	if weapon and weapon:isKindOf("Axe") and (who:hasSkills("luoyi|pojun|jiushi|jiuchi|jie|wenjiu|shenli|jieyuan") or self:getOverflow(who) > 0 or who:getCardCount() >= 4) then
		return weapon:getEffectiveId()
	end
	if armor and armor:isKindOf("EightDiagram") and who:hasSkills("leiji|nosleiji|olleiji|xiaoan") then return armor:getEffectiveId() end

	local lord = self.room:getLord()
	if lord and lord:hasLordSkill("hujia") and self:isEnemy(lord) and armor and armor:isKindOf("EightDiagram") and who:getKingdom() == "wei" then
		return armor:getEffectiveId()
	end

	if (weapon and weapon:isKindOf("SPMoonSpear") and self:hasSkills("guidao|longdan|guicai|jilve|huanshi|qingguo|kanpo|yueying|yuechao|guanxi", who)) then
		return weapon:getEffectiveId()
	end
	if (weapon and who:hasSkill("liegong|anjian")) then return weapon:getEffectiveId() end

	if weapon then
		for _, friend in ipairs(self.friends) do
			if who:distanceTo(friend) < who:getAttackRange(false) and self:isWeak(friend) and not self:doNotDiscard(who, "e", true) then return weapon:getEffectiveId() end
		end
	end
end

function SmartAI:getValuableCard(who)
	local weapon = who:getWeapon()
	local armor = who:getArmor()
	local offhorse = who:getOffensiveHorse()
	local defhorse = who:getDefensiveHorse()
	local treasure = who:getTreasure()
	
	if treasure then
		if treasure:isKindOf("LongPheasantTailFeatherPurpleGoldCrown") then
			return treasure:getEffectiveId()
		end
		if (treasure:isKindOf("Yuhangtu") or treasure:isKindOf("Xingyenaixu")) and self:isWeak(who) then
			return treasure:getEffectiveId()
		end
		if treasure:isKindOf("Cangbaotu") and not who:getPile("cangbaotu_pile"):isEmpty() then
			return treasure:getEffectiveId()
		end
	end
	
	self:sort(self.friends, "hp")
	local friend
	if #self.friends > 0 then friend = self.friends[1] end
	if friend and self:isWeak(friend) and who:distanceTo(friend) <= who:getAttackRange(false) and not self:doNotDiscard(who, "e", true) then
		if weapon and who:distanceTo(friend) > 1 then
			return weapon:getEffectiveId()
		end
		if offhorse and who:distanceTo(friend) > 1 then
			return offhorse:getEffectiveId()
		end
	end

	if weapon then
		if (weapon:isKindOf("MoonSpear") and who:hasSkill("keji") and who:getHandcardNum() > 5) or (weapon:isKindOf("Ssyuegui") or weapon:isKindOf("Ssfengchan")) or who:hasSkills("qiangxi|zhulou|taichen|yujian") then
			return weapon:getEffectiveId()
		end
	end

	local equips = sgs.QList2Table(who:getEquips())
	for _, equip in ipairs(equips) do
		if who:hasSkill("longhun") and equip:getSuit() ~= sgs.Card_Diamond then return equip:getEffectiveId() end
		if who:hasSkills("guose|yanxiao") and equip:getSuit() == sgs.Card_Diamond then return equip:getEffectiveId() end
		if who:hasSkill("baobian") and who:getHp() <= 2 then return  equip:getEffectiveId() end
		if who:hasSkills("qixi|duanliang|ol_duanliang|yinling|guidao") and equip:isBlack() then return equip:getEffectiveId() end
		if who:hasSkills("weiliu") then return equip:getEffectiveId() end
		if who:hasSkills("wusheng|jijiu|xueji|nosfuhun") and equip:isRed() then  return equip:getEffectiveId() end
		if who:hasSkills("hualin") and equip:getSuit() == sgs.Card_Spade then return equip:getEffectiveId() end	--化鳞黑桃装备
		if who:hasSkills(sgs.need_equip_skill) and not who:hasSkills(sgs.lose_equip_skill) then return equip:getEffectiveId() end
	end

	if armor and self:evaluateArmor(armor, who) > 3 and not self:needToThrowArmor(who) and not self:doNotDiscard(who, "e") then
		return armor:getEffectiveId()
	end

	if armor and armor:isKindOf("SilverLion") and who:hasSkills(sgs.use_lion_skill) then
		return armor:getEffectiveId()
	end

	if armor and armor:isKindOf("Neneko") and who:getMark("&neneko_record_basic") + who:getMark("&neneko_record_trick") > 0 then
		return armor:getEffectiveId()
	end

	if offhorse then
		if who:hasSkills("nosqianxi|kuanggu|duanbing|qianxi") then
			return offhorse:getEffectiveId()
		end
	end
	
	local slash = sgs.Sanguosha:cloneCard("slash")
	if defhorse and not self:doNotDiscard(who, "e")
		and not (self.player:hasWeapon("kylin_bow") and self.player:canSlash(who) and self:slashIsEffective(slash, who, self.player)
				and (getCardsNum("Jink", who, self.player) < 1 or sgs.card_lack[who:objectName()].Jink == 1)) then
		slash:deleteLater()
		return defhorse:getEffectiveId()
	end
	slash:deleteLater()

	if armor and not self:needToThrowArmor(who) and not self:doNotDiscard(who, "e") then
		return armor:getEffectiveId()
	end

	if offhorse and who:getHandcardNum() > 1 then
		if not self:doNotDiscard(who, "e", true) then
			for _, friend in ipairs(self.friends) do
				if who:distanceTo(friend) == who:getAttackRange() and who:getAttackRange() > 1 then
					return offhorse:getEffectiveId()
				end
			end
		end
	end

	if weapon and who:getHandcardNum() > 1 then
		if not self:doNotDiscard(who, "e", true) then
			for _, friend in ipairs(self.friends) do
				if (who:distanceTo(friend) <= who:getAttackRange()) and (who:distanceTo(friend) > 1) then
					return weapon:getEffectiveId()
				end
			end
		end
	end

	if treasure then
		if treasure:isKindOf("WoodenOx") and who:getPile("wooden_ox"):length() > 1 then
			return treasure:getEffectiveId()
		end
	end
end

function SmartAI:useCardSnatchOrDismantlement(card, use)
	local isSkillCard = card:isKindOf("YinlingCard") or card:isKindOf("DanshouCard")
	local isJixi = card:getSkillName() == "jixi"
	local isDiscard = (not card:isKindOf("Snatch"))
	local name = card:isKindOf("YinlingCard") and "yinling" or card:isKindOf("DanshouCard") and "danshou" or card:objectName()
	local using_2013 = (name == "dismantlement") and self.room:getMode() == "02_1v1" and sgs.GetConfig("1v1/Rule", "Classical") ~= "Classical"
	if not isSkillCard and self.player:hasSkill("noswuyan") then return end
	local players = self.room:getOtherPlayers(self.player)
	local tricks
	local usecard = false

	local targets = {}
	local targets_num = isSkillCard and 1 or (1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card))
	if use.isDummy and use.extra_target then targets_num = targets_num + use.extra_target end
	local lx = self.room:findPlayerBySkillName("huangen")

	local addTarget = function(player, cardid)
		if not table.contains(targets, player:objectName())
			and (not use.current_targets or not table.contains(use.current_targets, player:objectName()))
			and not (use.to and use.to:length() > 0 and player:hasSkill("danlao"))
			and not (use.to and use.to:length() > 0 and lx and self:isEnemy(lx) and lx:getHp() > targets_num / 2)
			and not (player:getWeapon() and player:getWeapon():isKindOf("ThunderclapCatapult"))
			then
			if not usecard then
				use.card = card
				usecard = true
			end
			table.insert(targets, player:objectName())
			if usecard and use.to and use.to:length() < targets_num then
				use.to:append(player)
				if not use.isDummy then
					sgs.Sanguosha:getCard(cardid):setFlags("AIGlobal_SDCardChosen_" .. name)
					if use.to:length() == 1 and math.random() < 0.5 then self:speak(use.card:getClassName(), self.player:isFemale()) end
				end
			end
			if #targets == targets_num then return true end
		end
	end

	players = self:exclude(players, card)
	if not isSkillCard and not using_2013 then
		for _, player in ipairs(players) do
			if not player:getJudgingArea():isEmpty() and (self:hasTrickEffective(card, player) or isSkillCard)
				and ((player:containsTrick("lightning") and self:getFinalRetrial(player) == 2) or #self.enemies == 0) then
				tricks = player:getCards("j")
				for _, trick in sgs.qlist(tricks) do
					if trick:isKindOf("Lightning") and (not isDiscard or self.player:canDiscard(player, trick:getId())) then
						if addTarget(player, trick:getEffectiveId()) then return end
					end
				end
			end
		end
	end

	local enemies = {}
	if #self.enemies == 0 and self:getOverflow() > 0 then
		local lord = self.room:getLord()
		for _, player in ipairs(players) do
			if not self:isFriend(player) and (self:hasTrickEffective(card, player) or isSkillCard) then
				if lord and self.player:isLord() then
					local kingdoms = {}
					if lord:getGeneral():isLord() then table.insert(kingdoms, lord:getGeneral():getKingdom()) end
					if lord:getGeneral2() and lord:getGeneral2():isLord() then table.insert(kingdoms, lord:getGeneral2():getKingdom()) end
					if not table.contains(kingdoms, player:getKingdom()) and not lord:hasSkill("yongsi") then table.insert(enemies, player) end
				elseif lord and player:objectName() ~= lord:objectName() then
					table.insert(enemies, player)
				elseif not lord then
					table.insert(enemies, player)
				end
			end
		end
		enemies = self:exclude(enemies, card)
		local temp = {}
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkills("tuntian+guidao") and enemy:hasSkills("zaoxian|jixi|ziliang|leiji|nosleiji|olleiji") then continue end
			if self:hasTrickEffective(card, enemy) or isSkillCard then
				table.insert(temp, enemy)
			end
		end
		enemies = temp
		self:sort(enemies, "defense")
		enemies = sgs.reverse(enemies)
	else
		enemies = self:exclude(self.enemies, card)
		local temp = {}
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkills("tuntian+guidao") and enemy:hasSkills("zaoxian|jixi|ziliang|leiji|nosleiji|olleiji") then continue end
			if self:hasTrickEffective(card, enemy) or isSkillCard then
				table.insert(temp, enemy)
			end
		end
		enemies = temp
		self:sort(enemies, "defense")
	end
	
	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() then
			if enemy:getTreasure() and enemy:getTreasure():isKindOf("LongPheasantTailFeatherPurpleGoldCrown")
			and (not isDiscard or self.player:canDiscard(enemy, enemy:getTreasure():getEffectiveId()))
			and not self:isEquipLocking(enemy)
			then
				if addTarget(enemy, enemy:getTreasure():getEffectiveId()) then return end
			end
		end
	end

	if self:slashIsAvailable() then
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		local slash = sgs.Sanguosha:cloneCard("slash")
		self:useCardSlash(slash, dummyuse)
		slash:deleteLater()
		if not dummyuse.to:isEmpty() then
			local tos = self:exclude(dummyuse.to, card)
			for _, to in ipairs(tos) do
				if to:getHandcardNum() == 1 and to:getHp() <= 2 and self:hasLoseHandcardEffective(to) and not to:hasSkills("kongcheng|tianming") and (self:hasTrickEffective(card, to) or isSkillCard)
					and (not self:hasEightDiagramEffect(to) or IgnoreArmor(self.player, to)) then
					if addTarget(to, to:getRandomHandCardId()) then return end
				end
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() and (self:hasTrickEffective(card, enemy) or isSkillCard) then
			local dangerous = self:getDangerousCard(enemy)
			if dangerous and (not isDiscard or self.player:canDiscard(enemy, dangerous)) and not self:isEquipLocking(enemy) then
				if addTarget(enemy, dangerous) then return end
			end
		end
	end

	self:sort(self.friends_noself, "defense")
	local friends = self:exclude(self.friends_noself, card)
	if not isSkillCard and not using_2013 then
		for _, friend in ipairs(friends) do
			if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) and not friend:containsTrick("YanxiaoCard")
				and (self:hasTrickEffective(card, friend) or isSkillCard) then
				local cardchosen
				tricks = friend:getJudgingArea()
				for _, trick in sgs.qlist(tricks) do
					if trick:isKindOf("Indulgence") and (not isDiscard or self.player:canDiscard(friend, trick:getId())) then
						if friend:getHp() <= friend:getHandcardNum() or friend:isLord() or name == "snatch" then
							cardchosen = trick:getEffectiveId()
							break
						end
					end
					if trick:isKindOf("SupplyShortage") and (not isDiscard or self.player:canDiscard(friend, trick:getId())) then
						cardchosen = trick:getEffectiveId()
						break
					end
					if trick:isKindOf("Indulgence") and (not isDiscard or self.player:canDiscard(friend, trick:getId())) then
						cardchosen = trick:getEffectiveId()
						break
					end
				end
				if cardchosen then
					if addTarget(friend, cardchosen) then return end
				end
			end
		end
	end

	local hasLion, target
	for _, friend in ipairs(friends) do
		if (self:hasTrickEffective(card, friend) or isSkillCard) and self:needToThrowArmor(friend) and (not isDiscard or self.player:canDiscard(friend, friend:getArmor():getEffectiveId())) and not self:isEquipLocking(friend) then
			hasLion = true
			target = friend
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() and (self:hasTrickEffective(card, enemy) or isSkillCard) then
			local valuable = self:getValuableCard(enemy)
			if valuable and (not isDiscard or self.player:canDiscard(enemy, valuable)) and not self:isEquipLocking(enemy) then
				if addTarget(enemy, valuable) then return end
			end
		end
	end

	local new_enemies = table.copyFrom(enemies)
	local compare_JudgingArea = function(a, b)
		return a:getJudgingArea():length() > b:getJudgingArea():length()
	end
	table.sort(new_enemies, compare_JudgingArea)
	local yanxiao_card, yanxiao_target, yanxiao_prior
	if not isSkillCard and not using_2013 then
		for _, enemy in ipairs(new_enemies) do
			for _, acard in sgs.qlist(enemy:getJudgingArea()) do
				if acard:isKindOf("YanxiaoCard") and (not isDiscard or self.player:canDiscard(enemy, acard:getId())) and (self:hasTrickEffective(card, enemy) or isSkillCard) then
					yanxiao_card = acard
					yanxiao_target = enemy
					if enemy:containsTrick("indulgence") or enemy:containsTrick("supply_shortage") then yanxiao_prior = true end
					break
				end
			end
			if yanxiao_card and yanxiao_target then break end
		end
		if yanxiao_prior and yanxiao_card and yanxiao_target then
			if addTarget(yanxiao_target, yanxiao_card:getEffectiveId()) then return end
		end
	end

	for _, enemy in ipairs(enemies) do
		local cards = sgs.QList2Table(enemy:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
		if #cards <= 2 and not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h", true) and (self:hasTrickEffective(card, enemy) or isSkillCard)then
			for _, cc in ipairs(cards) do
				if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
					if addTarget(enemy, self:getCardRandomly(enemy, "h")) then return end
				end
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() and (self:hasTrickEffective(card, enemy) or isSkillCard) then
			if enemy:hasSkills("jijiu|qingnang|jieyin") then
				local cardchosen
				local equips = { enemy:getDefensiveHorse(), enemy:getArmor(), enemy:getOffensiveHorse(), enemy:getWeapon(),enemy:getTreasure() }
				for _, equip in ipairs(equips) do
					if equip and (not enemy:hasSkill("jijiu") or equip:isRed()) and (not isDiscard or self.player:canDiscard(enemy, equip:getEffectiveId())) and not self:isEquipLocking(enemy) then
						cardchosen = equip:getEffectiveId()
						break
					end
				end

				if not cardchosen and not enemy:isKongcheng() and enemy:getHandcardNum() < 3 and self:isWeak(enemy)
					and (not self:needKongcheng(enemy) and enemy:getHandcardNum() == 1)
					and (not isDiscard or self.player:canDiscard(enemy, "h")) then
					cardchosen = self:getCardRandomly(enemy, "h")
				end
				if not cardchosen and enemy:getDefensiveHorse() and (not isDiscard or self.player:canDiscard(enemy, enemy:getDefensiveHorse():getEffectiveId())) and not self:isEquipLocking(enemy) then cardchosen = enemy:getDefensiveHorse():getEffectiveId() end
				if not cardchosen and enemy:getArmor() and not self:needToThrowArmor(enemy) and (not isDiscard or self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) and not self:isEquipLocking(enemy) then
					cardchosen = enemy:getArmor():getEffectiveId()
				end

				if cardchosen then
					if addTarget(enemy, cardchosen) then return end
				end
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if enemy:hasArmorEffect("eight_diagram") and enemy:getArmor() and not self:needToThrowArmor(enemy)
			and (not isDiscard or self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) and not self:isEquipLocking(enemy) and (self:hasTrickEffective(card, enemy) or isSkillCard) then
			addTarget(enemy, enemy:getArmor():getEffectiveId())
		end
	end

	for i = 1, 2 + (isJixi and 3 or 0), 1 do
		for _, enemy in ipairs(enemies) do
			if not enemy:isNude() and not (self:needKongcheng(enemy) and i <= 2) and not self:doNotDiscard(enemy) and (self:hasTrickEffective(card, enemy) or isSkillCard) then
				if (enemy:getHandcardNum() == i and sgs.getDefenseSlash(enemy, self) < 6 + (isJixi and 6 or 0) and enemy:getHp() <= 3 + (isJixi and 2 or 0)) then
					local cardchosen
					if self.player:distanceTo(enemy) == self.player:getAttackRange() + 1 and enemy:getDefensiveHorse() and not self:doNotDiscard(enemy, "e")
						and (not isDiscard or self.player:canDiscard(enemy, enemy:getDefensiveHorse():getEffectiveId())) and not self:isEquipLocking(enemy) then
						cardchosen = enemy:getDefensiveHorse():getEffectiveId()
					elseif enemy:getArmor() and not self:needToThrowArmor(enemy) and not self:doNotDiscard(enemy, "e")
						and (not isDiscard or self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) and not self:isEquipLocking(enemy) then
						cardchosen = enemy:getArmor():getEffectiveId()
					elseif not isDiscard or self.player:canDiscard(enemy, "h") then
						cardchosen = self:getCardRandomly(enemy, "h")
					end
					if cardchosen then
						if addTarget(enemy, cardchosen) then return end
					end
				end
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() then
			local valuable = self:getValuableCard(enemy)
			if valuable and (not isDiscard or self.player:canDiscard(enemy, valuable)) and not self:isEquipLocking(enemy) and (self:hasTrickEffective(card, enemy) or isSkillCard) then
				if addTarget(enemy, valuable) then return end
			end
		end
	end

	if hasLion and (not isDiscard or self.player:canDiscard(target, target:getArmor():getEffectiveId())) and not self:isEquipLocking(target) and (self:hasTrickEffective(card, target) or isSkillCard) then
		if addTarget(target, target:getArmor():getEffectiveId()) then return end
	end

	if not isSkillCard and not using_2013
		and yanxiao_card and yanxiao_target and (not isDiscard or self.player:canDiscard(yanxiao_target, yanxiao_card:getId())) then
		if addTarget(yanxiao_target, yanxiao_card:getEffectiveId()) then return end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") and (self:hasTrickEffective(card, enemy) or isSkillCard)
			and enemy:hasSkills(sgs.cardneed_skill) and (not isDiscard or self.player:canDiscard(enemy, "h")) then
			if addTarget(enemy, self:getCardRandomly(enemy, "h")) then return end
		end
	end

	for _, enemy in ipairs(enemies) do
		if enemy:hasEquip() and not self:doNotDiscard(enemy, "e") and (self:hasTrickEffective(card, enemy) or isSkillCard) then
			local cardchosen
			if enemy:getDefensiveHorse() and (not isDiscard or self.player:canDiscard(enemy, enemy:getDefensiveHorse():getEffectiveId())) and not self:isEquipLocking(enemy) then
				cardchosen = enemy:getDefensiveHorse():getEffectiveId()
			elseif enemy:getArmor() and not self:needToThrowArmor(enemy) and (not isDiscard or self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) and not self:isEquipLocking(enemy) then
				cardchosen = enemy:getArmor():getEffectiveId()
			elseif enemy:getOffensiveHorse() and (not isDiscard or self.player:canDiscard(enemy, enemy:getOffensiveHorse():getEffectiveId())) and not self:isEquipLocking(enemy) then
				cardchosen = enemy:getOffensiveHorse():getEffectiveId()
			elseif enemy:getWeapon() and (not isDiscard or self.player:canDiscard(enemy, enemy:getWeapon():getEffectiveId())) and not self:isEquipLocking(enemy) then
				cardchosen = enemy:getWeapon():getEffectiveId()
			end
			if cardchosen then
				if addTarget(enemy, cardchosen) then return end
			end
		end
	end

	if name == "snatch" or self:getOverflow() > 0 then
		for _, enemy in ipairs(enemies) do
			local equips = enemy:getEquips()
			if not enemy:isNude() and not self:doNotDiscard(enemy, "he") and (self:hasTrickEffective(card, enemy) or isSkillCard) then
				local cardchosen
				if not equips:isEmpty() and not self:doNotDiscard(enemy, "e") then
					cardchosen = self:getCardRandomly(enemy, "e")
				else
					cardchosen = self:getCardRandomly(enemy, "h") end
				if cardchosen then
					if addTarget(enemy, cardchosen) then return end
				end
			end
		end
	end
end

SmartAI.useCardSnatch = SmartAI.useCardSnatchOrDismantlement

sgs.ai_use_value.Snatch = 9
sgs.ai_use_priority.Snatch = 4.3
sgs.ai_keep_value.Snatch = 3.46

sgs.dynamic_value.control_card.Snatch = true

SmartAI.useCardDismantlement = SmartAI.useCardSnatchOrDismantlement

sgs.ai_use_value.Dismantlement = 5.6
sgs.ai_use_priority.Dismantlement = 4.4
sgs.ai_keep_value.Dismantlement = 3.44

sgs.dynamic_value.control_card.Dismantlement = true

sgs.ai_choicemade_filter.cardChosen.snatch = function(self, player, promptlist)
	local from = findPlayerByObjectName(self.room, promptlist[4])
	local to = findPlayerByObjectName(self.room, promptlist[5])
	if from and to then
		local id = tonumber(promptlist[3])
		local place = self.room:getCardPlace(id)
		local card = sgs.Sanguosha:getCard(id)
		local intention = 70
		if to:hasSkills("tuntian+zaoxian") and to:getPile("field") == 2 and to:getMark("zaoxian") == 0 then intention = 0 end
		if place == sgs.Player_PlaceDelayedTrick then
			if not card:isKindOf("Disaster") then intention = -intention else intention = 0 end
			if card:isKindOf("YanxiaoCard") then intention = -intention end
		elseif place == sgs.Player_PlaceEquip then
			if card:isKindOf("Armor") and self:evaluateArmor(card, to) <= -2 then intention = 0 end
			if card:isKindOf("SilverLion") then
				if to:getLostHp() > 1 then
					if to:hasSkills(sgs.use_lion_skill) then
						intention = self:willSkipPlayPhase(to) and -intention or 0
					else
						intention = self:isWeak(to) and -intention or 0
					end
				else
					intention = 0
				end
			elseif to:hasSkills(sgs.lose_equip_skill) then
				if self:isWeak(to) and (card:isKindOf("DefensiveHorse") or card:isKindOf("Armor")) then
					intention = math.abs(intention)
				else
					intention = 0
				end
			end
			if promptlist[2] == "snatch" and (card:isKindOf("OffensiveHorse") or card:isKindOf("Weapon")) and self:isFriend(from, to) then
				local canAttack
				for _, p in sgs.qlist(self.room:getOtherPlayers(from)) do
					if from:inMyAttackRange(p) and self:isEnemy(p, from) then canAttack = true break end
				end
				if not canAttack then intention = 0 end
			end
		elseif place == sgs.Player_PlaceHand then
			if self:needKongcheng(to, true) and to:getHandcardNum() == 1 then
				intention = 0
			end
		end
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_choicemade_filter.cardChosen.dismantlement = sgs.ai_choicemade_filter.cardChosen.snatch

function SmartAI:useCardCollateral(card, use)
	if self.player:hasSkill("noswuyan") then return end
	local fromList = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local toList   = sgs.QList2Table(self.room:getAlivePlayers())

	local cmp = function(a, b)
		local alevel = self:objectiveLevel(a)
		local blevel = self:objectiveLevel(b)

		if alevel ~= blevel then return alevel > blevel end

		local anum = getCardsNum("Slash", a)
		local bnum = getCardsNum("Slash", b)

		if anum ~= bnum then return anum < bnum end
		return a:getHandcardNum() < b:getHandcardNum()
	end

	table.sort(fromList, cmp)
	self:sort(toList, "defense")

	local needCrossbow = false
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and self:objectiveLevel(enemy) > 3
			and sgs.isGoodTarget(enemy, self.enemies, self) and not self:slashProhibit(nil, enemy) then
			needCrossbow = true
			break
		end
	end

	needCrossbow = needCrossbow and self:getCardsNum("Slash") > 2 and not self.player:hasSkills("paoxiao|xingxiong") and not self.player:hasSkill("kuangcai")

	if needCrossbow then
		for i = #fromList, 1, -1 do
			local friend = fromList[i]
			if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
				and friend:getWeapon() and friend:getWeapon():isKindOf("Crossbow") and self:hasTrickEffective(card, friend) then
				for _, enemy in ipairs(toList) do
					if friend:canSlash(enemy, nil) and friend:objectName() ~= enemy:objectName() then
						if not use.isDummy then self.room:setPlayerFlag(self.player, "needCrossbow") end
						use.card = card
						if use.to then use.to:append(friend) end
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end

	local n = nil
	local final_enemy = nil
	for _, enemy in ipairs(fromList) do
		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName()))
			and self:hasTrickEffective(card, enemy)
			and not self:hasSkills(sgs.lose_equip_skill, enemy)
			and not (enemy:hasSkill("weimu") and card:isBlack())
			and not (enemy:hasSkill("xiemu") and card:isBlack() and enemy:getMark("@xiemu_" .. self.player:getKingdom()) > 0)
			and not (enemy:hasSkill("tuntian") and enemy:hasSkill("zaoxian"))
			and self:objectiveLevel(enemy) >= 0
			and enemy:getWeapon() and not enemy:getWeapon():isKindOf("ThunderclapCatapult") then

			for _, enemy2 in ipairs(toList) do
				if enemy:canSlash(enemy2) and self:objectiveLevel(enemy2) > 3 and enemy:objectName() ~= enemy2:objectName() then
					n = 1
					final_enemy = enemy2
					break
				end
			end

			if not n then
				for _, enemy2 in ipairs(toList) do
					if enemy:canSlash(enemy2) and self:objectiveLevel(enemy2) <=3 and self:objectiveLevel(enemy2) >=0 and enemy:objectName() ~= enemy2:objectName() then
						n = 1
						final_enemy = enemy2
						break
					end
				end
			end

			if not n then
				for _, friend in ipairs(toList) do
					if enemy:canSlash(friend) and self:objectiveLevel(friend) < 0 and enemy:objectName() ~= friend:objectName()
							and (self:needToLoseHp(friend, enemy, true, true) or self:getDamagedEffects(friend, enemy, true)) then
						n = 1
						final_enemy = friend
						break
					end
				end
			end

			if not n then
				for _, friend in ipairs(toList) do
					if enemy:canSlash(friend) and self:objectiveLevel(friend) < 0 and enemy:objectName() ~= friend:objectName()
							and (getKnownCard(friend, self.player, "Jink", true, "he") >= 2 or getCardsNum("Slash", enemy) < 1) then
						n = 1
						final_enemy = friend
						break
					end
				end
			end

			if n then
				use.card = card
				if use.to then use.to:append(enemy) end
				if use.to then use.to:append(final_enemy) end
				return
			end
		end
		n = nil
	end

	for _, friend in ipairs(fromList) do
		if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
			and friend:getWeapon() and (getKnownCard(friend, self.player, "Slash", true, "he") > 0 or getCardsNum("Slash", friend) > 1 and friend:getHandcardNum() >= 4)
			and self:hasTrickEffective(card, friend)
			and self:objectiveLevel(friend) < 0
			and not self.room:isProhibited(self.player, friend, card) then

			for _, enemy in ipairs(toList) do
				if friend:canSlash(enemy, nil) and self:objectiveLevel(enemy) > 3 and friend:objectName() ~= enemy:objectName()
						and sgs.isGoodTarget(enemy, self.enemies, self) and not self:slashProhibit(nil, enemy) then
					use.card = card
					if use.to then use.to:append(friend) end
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end

	self:sortEnemies(toList)

	for _, friend in ipairs(fromList) do
		if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
			and friend:getWeapon() and friend:hasSkills(sgs.lose_equip_skill)
			and self:hasTrickEffective(card, friend)
			and self:objectiveLevel(friend) < 0
			and not (friend:getWeapon():isKindOf("Crossbow") and getCardsNum("Slash", friend) > 1)
			and not self.room:isProhibited(self.player, friend, card) then

			for _, enemy in ipairs(toList) do
				if friend:canSlash(enemy, nil) and friend:objectName() ~= enemy:objectName() then
					use.card = card
					if use.to then use.to:append(friend) end
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value.Collateral = 5.8
sgs.ai_use_priority.Collateral = 2.75
sgs.ai_keep_value.Collateral = 3.40

sgs.ai_card_intention.Collateral = function(self, card, from, tos)
	-- assert(#tos == 1)
	sgs.ai_collateral = true
	self.room:setTag("collateral_from_name", sgs.QVariant(from:objectName()))
end

sgs.dynamic_value.control_card.Collateral = true

sgs.ai_skill_cardask["collateral-slash"] = function(self, data, pattern, target2, target, prompt)
	-- self.player = killer
	-- target = user
	-- target2 = victim
	
	if not self:isFriend(target) and self.player:getWeapon() and self.player:getWeapon():isKindOf("ThunderclapCatapult") then
		return "."
	end
	
	if self:isFriend(target) and (target:hasFlag("needCrossbow") or
			(getCardsNum("Slash", target, self.player) >= 2 and self.player:getWeapon():isKindOf("Crossbow"))) then
		if target:hasFlag("needCrossbow") then self.room:setPlayerFlag(target, "-needCrossbow") end
		return "."
	end

	if self:isFriend(target2) and self:needLeiji(target2, self.player) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target2) then
				return slash:toString()
			end
		end
	end

	if target2 and (self:getDamagedEffects(target2, self.player, true) or self:needToLoseHp(target2, self.player, true)) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target2) and self:isFriend(target2) then
				return slash:toString()
			end
			if not self:slashIsEffective(slash, target2, self.player, true) and self:isEnemy(target2) then
				return slash:toString()
			end
		end
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:getDamagedEffects(target2, self.player, true) and self:isEnemy(target2) then
				return slash:toString()
			end
		end
	end

	if target2 and not self:hasSkills(sgs.lose_equip_skill) and self:isEnemy(target2) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target2) then
				return slash:toString()
			end
		end
	end
	if target2 and not self:hasSkills(sgs.lose_equip_skill) and self:isFriend(target2) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:slashIsEffective(slash, target2) then
				return slash:toString()
			end
		end
		for _, slash in ipairs(self:getCards("Slash")) do
			if (target2:getHp() > 3 and not self:canHit(target2, self.player, self:hasHeavySlashDamage(self.player, slash, target2)))
				and target2:getRole() ~= "lord" and self.player:getHandcardNum() > 1 then
					return slash:toString()
			end
			if self:needToLoseHp(target2, self.player) then return slash:toString() end
		end
	end
	self:speak("collateral", self.player:isFemale())
	return "."
end

local function hp_subtract_handcard(a,b)
	local diff1 = a:getHp() - a:getHandcardNum()
	local diff2 = b:getHp() - b:getHandcardNum()

	return diff1 < diff2
end

function SmartAI:enemiesContainsTrick(EnemyCount)
	local trick_all, possible_indul_enemy, possible_ss_enemy = 0, 0, 0
	local indul_num = self:getCardsNum("Indulgence")
	local ss_num = self:getCardsNum("SupplyShortage")
	local enemy_num, temp_enemy = 0

	local zhanghe = self.room:findPlayerBySkillName("qiaobian")
	if zhanghe and (not self:isEnemy(zhanghe) or zhanghe:isKongcheng() or not zhanghe:faceUp()) then zhanghe = nil end
	
	local zhanghe = self.room:findPlayerBySkillName("fahun")
	if zhanghe and (not self:isEnemy(zhanghe) or zhanghe:isKongcheng() or not zhanghe:faceUp()) then zhanghe = nil end
	
	local ol_caoren = self.room:findPlayerBySkillName("ol_jiewei")
	if ol_caoren and (not self:isEnemy(ol_caoren) or ol_caoren:isNude() or ol_caoren:faceUp()) then ol_caoren = nil end

	if self.player:hasSkill("guose") then
		for _, acard in sgs.qlist(self.player:getCards("he")) do
			if acard:getSuit() == sgs.Card_Diamond then indul_num = indul_num + 1 end
		end
	end

	if self.player:hasSkills("duanliang|ol_duanliang") then
		for _, acard in sgs.qlist(self.player:getCards("he")) do
			if acard:isBlack() then ss_num = ss_num + 1 end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if not enemy:containsTrick("YanxiaoCard") then
			if enemy:containsTrick("indulgence") then
				if not enemy:hasSkills("keji|heg_keji|conghui") and (not zhanghe or self:playerGetRound(enemy) >= self:playerGetRound(zhanghe)) and (not ol_caoren or self:playerGetRound(enemy) >= self:playerGetRound(ol_caoren)) then
					trick_all = trick_all + 1
					if not temp_enemy or temp_enemy:objectName() ~= enemy:objectName() then
						enemy_num = enemy_num + 1
						temp_enemy = enemy
					end
				end
			else
				possible_indul_enemy = possible_indul_enemy + 1
			end
			if self.player:distanceTo(enemy) == 1 or self.player:hasSkills("duanliang|ol_duanliang") and self.player:distanceTo(enemy) <= 2 then
				if enemy:containsTrick("supply_shortage") then
					if not self:hasSkills("shensu|jisu", enemy) and (not zhanghe or self:playerGetRound(enemy) >= self:playerGetRound(zhanghe)) and (not ol_caoren or self:playerGetRound(enemy) >= self:playerGetRound(ol_caoren)) then
						trick_all = trick_all + 1
						if not temp_enemy or temp_enemy:objectName() ~= enemy:objectName() then
							enemy_num = enemy_num + 1
							temp_enemy = enemy
						end
					end
				else
					possible_ss_enemy  = possible_ss_enemy + 1
				end
			end
		end
	end
	indul_num = math.min(possible_indul_enemy, indul_num)
	ss_num = math.min(possible_ss_enemy, ss_num)
	if not EnemyCount then
		return trick_all + indul_num + ss_num
	else
		return enemy_num + indul_num + ss_num
	end
end

function SmartAI:playerGetRound(player, source)
	if not player then return self.room:writeToConsole(debug.traceback()) end
	source = source or self.room:getCurrent()
	if player:objectName() == source:objectName() then return 0 end
	local players_num = self.room:alivePlayerCount()
	local round = (player:getSeat() - source:getSeat()) % players_num
	return round
end

function SmartAI:useCardIndulgence(card, use)
	local enemies = {}

	if #self.enemies == 0 then
		if sgs.turncount <= 1 and self.role == "lord" and not sgs.isRolePredictable()
			and sgs.evaluatePlayerRole(self.player:getNextAlive()) == "neutral"
			and not (self.player:hasLordSkill("shichou") and self.player:getNextAlive():getKingdom() == "shu") then
			enemies = self:exclude({self.player:getNextAlive()}, card)
		end
	else
		enemies = self:exclude(self.enemies, card)
	end

	local zhanghe = self.room:findPlayerBySkillName("qiaobian")
	local zhanghe_seat = zhanghe and zhanghe:faceUp() and not zhanghe:isKongcheng() and not self:isFriend(zhanghe) and zhanghe:getSeat() or 0
	
	local zhanghe = self.room:findPlayerBySkillName("fahun")
	local zhanghe_seat = zhanghe and zhanghe:faceUp() and not zhanghe:isKongcheng() and not self:isFriend(zhanghe) and zhanghe:getSeat() or 0
	
	local ol_caoren = self.room:findPlayerBySkillName("ol_jiewei")
	local ol_caoren_seat = ol_caoren and not ol_caoren:faceUp() and not ol_caoren:isNude() and not self:isFriend(ol_caoren) and ol_caoren:getSeat() or 0

	local sb_daqiao = self.room:findPlayerBySkillName("yanxiao")
	local yanxiao = sb_daqiao and not self:isFriend(sb_daqiao) and sb_daqiao:faceUp() and
					(getKnownCard(sb_daqiao, self.player, "diamond", nil, "he") > 0
					or sb_daqiao:getHandcardNum() + self:ImitateResult_DrawNCards(sb_daqiao, sb_daqiao:getVisibleSkillList(true)) > 3
					or sb_daqiao:containsTrick("YanxiaoCard"))

	if #enemies == 0 then return end

	local getvalue = function(enemy)
		if enemy:containsTrick("indulgence") or enemy:containsTrick("YanxiaoCard") then return -100 end
		if enemy:hasSkills("qiaobian|fahun") and not enemy:containsTrick("supply_shortage") and not enemy:containsTrick("indulgence") then return -100 end
		if zhanghe_seat > 0 and (self:playerGetRound(zhanghe) <= self:playerGetRound(enemy) and self:enemiesContainsTrick() <= 1 or not enemy:faceUp()) then
			return -100 end
		
		if enemy:hasSkill("ol_jiewei") and not enemy:faceUp() and not enemy:isNude() and not enemy:containsTrick("supply_shortage") and not enemy:containsTrick("indulgence") then return -100 end
		if ol_caoren_seat > 0 and (self:playerGetRound(ol_caoren) <= self:playerGetRound(enemy) and self:enemiesContainsTrick() <= 1 or not enemy:faceUp()) then
			return -100 end
		
		if yanxiao and (self:playerGetRound(sb_daqiao) <= self:playerGetRound(enemy) and self:enemiesContainsTrick(true) <= 1 or not enemy:faceUp()) then
			return -100 end

		local value = enemy:getHandcardNum() - enemy:getHp()

		--乐不思蜀优先级
		if enemy:hasSkills("noslijian|lijian|fanjian|neofanjian|dimeng|jijiu|jieyin|anxu|yongsi|zhiheng|manjuan|nosrende|rende|olrende|ol_rende|qixi|jixi|zhengnan|zhengnan_2018_new|qiaosi|kuangcai") then value = value + 10 end
		if enemy:hasSkills("houyuan|qice|guose|duanliang|ol_duanliang||yanxiao|nosjujian|luoshen|nosjizhi|jizhi|jilve|wansha|mingce|sizhan") then value = value + 5 end
		if enemy:hasSkills("guzheng|luoying|xiliang|guixin|lihun|yinling|gongxin|shenfen|ganlu|duoshi|jueji|zhenggong|moyue") then value = value + 3 end
		--Vup杀 高优先级
		if enemy:hasSkills("yishou|choucuo|xianwei|zhuoshi|shuoyi") then value = value + 10 end
		if enemy:hasSkills("zhuoshi|diyin|cangbao|juanyi|qianchang|quanneng_xiaonai|liucai") then value = value + 5 end
		if enemy:hasSkills("yinyou|xiange|youlian|heli|jieshuo|bianshi|xingxiong|jiyue") then value = value + 3 end
		
		if self:isWeak(enemy) then value = value + 3 end
		if enemy:isLord() then value = value + 3 end

		if self:objectiveLevel(enemy) < 3 then value = value - 10 end
		if not enemy:faceUp() then value = value - 10 end
		
		local wounded_num = 0
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:isWounded() then
				wounded_num = wounded_num + 1
			end
		end
		if enemy:hasSkill("sec_xingzhao") and wounded_num >= 3 then value = value - enemy:getHandcardNum() end
		--Vup杀 负优先级
		if enemy:hasSkills("zijian|liuyi|xuxiang|mengjian") then value = value - 5 end
		if enemy:hasSkills("mingdao|zhanmeng|zhulie|shitian|yuanchu") then value = value - 3 end
		
		if enemy:hasSkills("keji|heg_keji|shensu|conghui") then value = value - enemy:getHandcardNum() end
		if enemy:hasSkills("guanxing|xiuluo") then value = value - 5 end
		if enemy:hasSkills("lirang|longluo") then value = value - 5 end
		if enemy:hasSkills("tuxi|noszhenlie|guanxing|qinyin|zongshi|tiandu") then value = value - 3 end
		if enemy:hasSkill("conghui") then value = value - 20 end
		if enemy:hasSkill("qianxun") and not enemy:isKongcheng() then value = value - 20 end
		if enemy:hasSkill("kongsheng") and not enemy:isKongcheng() then value = value - 20 end
		if self:needBear(enemy) then value = value - 20 end
		if not sgs.isGoodTarget(enemy, self.enemies, self) then value = value - 1 end
		if getKnownCard(enemy, self.player, "Dismantlement", true) > 0 then value = value + 2 end
		value = value + (self.room:alivePlayerCount() - self:playerGetRound(enemy)) / 2
		return value
	end

	local cmp = function(a,b)
		return getvalue(a) > getvalue(b)
	end

	table.sort(enemies, cmp)
	local target = enemies[1]
	if getvalue(target) > -100 then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value.Indulgence = 8
sgs.ai_use_priority.Indulgence = 0.5
sgs.ai_card_intention.Indulgence = 120
sgs.ai_keep_value.Indulgence = 3.5

sgs.dynamic_value.control_usecard.Indulgence = true

function SmartAI:willUseLightning(card)
	if not card then self.room:writeToConsole(debug.traceback()) return false end
	if self.player:containsTrick("lightning") then return end
	if self.player:hasSkill("weimu") and card:isBlack() then return end
	if self.room:isProhibited(self.player, self.player, card) then return end
	
	for _, aplayer in ipairs(self.friends) do	--友方有人有“娴静”直接挂
		if aplayer:hasSkill("xianjing") then
			return true
		end
	end
	
	local rebel_num = sgs.current_mode_players["rebel"]
	local loyal_num = sgs.current_mode_players["loyalist"]
	if self.player:getRole() == "renegade" and not sgs.explicit_renegade and rebel_num == 0 and loyal_num > 0 then return end

	local function hasDangerousFriend()
		local hashy = false
		for _, aplayer in ipairs(self.enemies) do
			if aplayer:hasSkill("hongyan") then hashy = true break end
		end
		for _, aplayer in ipairs(self.enemies) do
			if aplayer:hasSkills("guanxing|mengjian|yahe") or (aplayer:hasSkill("gongxin") and hashy)
			or aplayer:hasSkill("xinzhan") then
				if self:isFriend(aplayer:getNextAlive()) then return true end
			end
		end
		return false
	end

	if self:getFinalRetrial(self.player) == 2 then
	return
	elseif self:getFinalRetrial(self.player) == 1 then
		return true
	elseif not hasDangerousFriend() then
		--需要用牌就直接用
		if self.player:hasSkills(sgs.need_kongcheng.."|shuoyi|xixue|zhanshu|zhuoshi|jiezhi_zl") or self.player:getMark("&motiao_using") > 0 or self:needKongcheng() or self.player:getHandcardNum() > self:getBestKeepHandcardNum() then
			return true
		end
		
		local players = self.room:getAllPlayers()
		players = sgs.QList2Table(players)

		local friends = 0
		local enemies = 0

		for _,player in ipairs(players) do
			if self:objectiveLevel(player) >= 3 and not player:hasSkill("hongyan") and not player:hasSkill("wuyan")
			  and not (player:hasSkill("weimu") and card:isBlack()) and not (player:hasSkill("xianrou") and card:getSuit() == sgs.Card_Spade) then
				enemies = enemies + 1
			elseif self:isFriend(player) and not player:hasSkill("hongyan") and not player:hasSkill("wuyan")
			  and not (player:hasSkill("weimu") and card:isBlack()) and not (player:hasSkill("xianrou") and card:getSuit() == sgs.Card_Spade) then
				friends = friends + 1
			end
		end

		local ratio

		if friends == 0 then ratio = 999
		else ratio = 1.0*enemies/friends
		end

		if ratio > 1.2 then		--五对四才不挂
			return true
		end
	end
end

function SmartAI:useCardLightning(card, use)
	if self:willUseLightning(card) then
		use.card = card
	end
end

sgs.ai_use_priority.Lightning = 0
sgs.dynamic_value.lucky_chance.Lightning = true

sgs.ai_keep_value.Lightning = -1

sgs.ai_skill_askforag.amazing_grace = function(self, card_ids)

	local NextPlayerCanUse, NextPlayerisEnemy
	local NextPlayer = self.player:getNextAlive()
	if sgs.turncount > 1 and not self:willSkipPlayPhase(NextPlayer) then
		if self:isFriend(NextPlayer) and sgs.evaluatePlayerRole(NextPlayer) ~= "neutral" then
			NextPlayerCanUse = true
		else
			NextPlayerisEnemy = true
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("lihun") and enemy:faceUp() and not NextPlayer:faceUp() and NextPlayer:getHandcardNum() > 4 and NextPlayer:isMale() then
			NextPlayerCanUse = false
		end
	end

	local cards = {}
	local trickcard = {}
	for _, card_id in ipairs(card_ids) do
		local acard = sgs.Sanguosha:getCard(card_id)
		table.insert(cards, acard)
		if acard:isKindOf("TrickCard") then
			table.insert(trickcard , acard)
		end
	end

	local nextfriend_num = 0
	local aplayer = self.player:getNextAlive()
	for i =1, self.player:aliveCount() do
		if self:isFriend(aplayer) then
			aplayer = aplayer:getNextAlive()
			nextfriend_num = nextfriend_num + 1
		else
			break
		end
	end

	local SelfisCurrent
	if self.room:getCurrent():objectName() == self.player:objectName() then SelfisCurrent = true end

---------------

	local needbuyi
	for _, friend in ipairs(self.friends) do
		if friend:hasSkill("buyi") and self.player:getHp() == 1 then
			needbuyi = true
		end
	end
	if needbuyi then
		local maxvaluecard, minvaluecard
		local maxvalue, minvalue = -100, 100
		for _, bycard in ipairs(cards) do
			if not bycard:isKindOf("BasicCard") then
				local value = self:getUseValue(bycard)
				if value > maxvalue then
					maxvalue = value
					maxvaluecard = bycard
				end
				if value < minvalue then
					minvalue = value
					minvaluecard = bycard
				end
			end
		end
		if minvaluecard and NextPlayerCanUse then
			return minvaluecard:getEffectiveId()
		end
		if maxvaluecard then
			return maxvaluecard:getEffectiveId()
		end
	end

	local friendneedpeach, peach
	local peachnum, jinknum = 0, 0
	if NextPlayerCanUse then
		if (not self.player:isWounded() and NextPlayer:isWounded()) or
			(self.player:getLostHp() < self:getCardsNum("Peach")) or
			(not SelfisCurrent and self:willSkipPlayPhase() and self.player:getHandcardNum() + 2 > self.player:getMaxCards()) then
			friendneedpeach = true
		end
	end
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			peach = card:getEffectiveId()
			peachnum = peachnum + 1
		end
		if card:isKindOf("Jink") then jinknum = jinknum + 1 end
	end
	if (not friendneedpeach and peach) or peachnum > 1 then return peach end

	local exnihilo, jink, analeptic, nullification, snatch, dismantlement, indulgence
	for _, card in ipairs(cards) do
		if isCard("ExNihilo", card, self.player) then
			if not NextPlayerCanUse or (not self:willSkipPlayPhase() and (self.player:hasSkills("nosjizhi|jizhi|zhiheng|nosrende|rende") or not NextPlayer:hasSkills("nosjizhi|jizhi|zhiheng|nosrende|rende"))) then
				exnihilo = card:getEffectiveId()
			end
		elseif isCard("Jink", card, self.player) then
			jink = card:getEffectiveId()
		elseif isCard("Analeptic", card, self.player) then
			analeptic = card:getEffectiveId()
		elseif isCard("Nullification", card, self.player) then
			nullification = card:getEffectiveId()
		elseif isCard("Snatch", card, self.player) then
			snatch = card
		elseif isCard("Dismantlement", card, self.player) then
			dismantlement = card
		elseif isCard("Indulgence", card, self.player) then
			indulgence = card:getEffectiveId()
		end

	end

	for _, target in sgs.qlist(self.room:getAlivePlayers()) do
		if self:willSkipPlayPhase(target) or self:willSkipDrawPhase(target) then
			if nullification then return nullification
			elseif self:isFriend(target) and snatch and self:hasTrickEffective(snatch, target, self.player) and
				not self:willSkipPlayPhase() and self.player:distanceTo(target) == 1 then
				return snatch:getEffectiveId()
			elseif self:isFriend(target) and dismantlement and self:hasTrickEffective(dismantlement, target, self.player) and
				not self:willSkipPlayPhase() and self.player:objectName() ~= target:objectName() then
				return dismantlement:getEffectiveId()
			end
		end
	end

	if SelfisCurrent then
		if exnihilo then return exnihilo end
		if (jink or analeptic) and (self:getCardsNum("Jink") == 0 or (self:isWeak() and self:getOverflow() <= 0)) then
			return jink or analeptic
		end
		if indulgence then return indulgence end
	else
		local CP = self.room:getCurrent()
		local possible_attack = 0
		for _, enemy in ipairs(self.enemies) do
			if enemy:inMyAttackRange(self.player) and self:playerGetRound(CP, enemy) < self:playerGetRound(CP, self.player) then
				possible_attack = possible_attack + 1
			end
		end
		if possible_attack > self:getCardsNum("Jink") and self:getCardsNum("Jink") <= 2 and sgs.getDefenseSlash(self.player) <= 2 then
			if jink or analeptic or exnihilo then return jink or analeptic or exnihilo end
		else
			if exnihilo or indulgence then return exnihilo or indulgence end
		end
	end

	if nullification and (self:getCardsNum("Nullification") < 2 or not NextPlayerCanUse) then
		return nullification
	end

	if jinknum == 1 and jink and self:isEnemy(NextPlayer) and (NextPlayer:isKongcheng() or sgs.card_lack[NextPlayer:objectName()]["Jink"] == 1) then
		return jink
	end

	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		for _, skill in sgs.qlist(self.player:getVisibleSkillList(true)) do
			local callback = sgs.ai_cardneed[skill:objectName()]
			if type(callback) == "function" and callback(self.player, card, self) then
				return card:getEffectiveId()
			end
		end
	end

	local eightdiagram, silverlion, vine, renwang, DefHorse, OffHorse
	local weapon, crossbow, halberd, double, qinggang, axe, gudingdao, spmoonspear
	for _, card in ipairs(cards) do
		if card:isKindOf("EightDiagram") then eightdiagram = card:getEffectiveId()
		elseif card:isKindOf("SilverLion") then silverlion = card:getEffectiveId()
		elseif card:isKindOf("Vine") then vine = card:getEffectiveId()
		elseif card:isKindOf("RenwangShield") then renwang = card:getEffectiveId()
		elseif card:isKindOf("DefensiveHorse") and not self:getSameEquip(card) then DefHorse = card:getEffectiveId()
		elseif card:isKindOf("OffensiveHorse") and not self:getSameEquip(card) then OffHorse = card:getEffectiveId()
		elseif card:isKindOf("Crossbow") then crossbow = card
		elseif card:isKindOf("Halberd") then halberd = card:getEffectiveId()
		elseif card:isKindOf("DoubleSword") then double = card:getEffectiveId()
		elseif card:isKindOf("QinggangSword") then qinggang = card:getEffectiveId()
		elseif card:isKindOf("GudingBlade") then gudingdao = card:getEffectiveId()
		elseif card:isKindOf("Axe") then axe = card:getEffectiveId()
		elseif card:isKindOf("SPMoonSpear") then spmoonspear = card:getEffectiveId() end
		if card:isKindOf("Weapon") then weapon = card:getEffectiveId() end
	end

	if eightdiagram then
		local lord = getLord(self.player)
		if not self:hasSkills("yizhong|bazhen|linglong|xiangrui|bingshen") and self:hasSkills("tiandu|leiji|nosleiji|olleiji|noszhenlie|gushou|hongyan|xiaoan") and not self:getSameEquip(card) then
			return eightdiagram
		end
		if NextPlayerisEnemy and self:hasSkills("tiandu|leiji|nosleiji|olleiji|noszhenlie|gushou|hongyan|xiaoan", NextPlayer) and not self:getSameEquip(card, NextPlayer) then
			return eightdiagram
		end
		if self.role == "loyalist" and self.player:getKingdom()=="wei" and not self.player:hasSkills("bazhen|linglong|xiangrui") and
			lord and lord:hasLordSkill("hujia") and (lord:objectName() ~= NextPlayer:objectName() and NextPlayerisEnemy or lord:getArmor()) then
			return eightdiagram
		end
	end

	if silverlion then
		local lightning, canRetrial
		for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if aplayer:hasSkills("leiji|nosleiji|olleiji") and self:isEnemy(aplayer) then
				return silverlion
			end
			if aplayer:containsTrick("lightning") then
				lightning = true
			end
			if self:hasSkills(sgs.wizard_harm_skill, aplayer) and self:isEnemy(aplayer) then
				canRetrial = true
			end
		end
		if lightning and canRetrial then return silverlion end
		if self.player:isChained() then
			for _, friend in ipairs(self.friends) do
				if friend:hasArmorEffect("vine") and friend:isChained() then
					return silverlion
				end
			end
		end
		if self.player:isWounded() then return silverlion end
	end

	if vine then
		if sgs.ai_armor_value.vine(self.player, self) > 0 and self.room:alivePlayerCount() <= 3 then
			return vine
		end
	end

	if renwang then
		if sgs.ai_armor_value.renwang_shield(self.player, self) > 0 and self:getCardsNum("Jink") == 0 then return renwang end
	end

	if DefHorse and (not self.player:hasSkill("leiji|nosleiji|olleiji|xiaoan") or self:getCardsNum("Jink") == 0) then
		local before_num, after_num = 0, 0
		for _, enemy in ipairs(self.enemies) do
			if enemy:canSlash(self.player, nil, true) then
				before_num = before_num + 1
			end
			if enemy:canSlash(self.player, nil, true, 1) then
				after_num = after_num + 1
			end
		end
		if before_num > after_num and (self:isWeak() or self:getCardsNum("Jink") == 0) then return DefHorse end
	end

	if analeptic then
		local slashs = self:getCards("Slash")
		for _, enemy in ipairs(self.enemies) do
			local hit_num = 0
			for _, slash in ipairs(slashs) do
				if self:slashIsEffective(slash, enemy) and self.player:canSlash(enemy, slash) and self:slashIsAvailable() then
					hit_num = hit_num + 1
					if getCardsNum("Jink", enemy) < 1
						or enemy:isKongcheng()
						or self:canLiegong(enemy, self.player)
						or self.player:hasSkills("tieji|wushuang|dahe|qianxi")
						or (self.player:hasSkills("luafenyin") and self.player:getLostHp() >= 3)
						or (self.player:hasSkills("xingyao_if") and countCheer(self.player) >= 5)
						or self.player:hasSkill("roulin") and enemy:isFemale()
						or (self.player:hasWeapon("axe") or self:getCardsNum("Axe") > 0) and self.player:getCards("he"):length() > 4
						then
						return analeptic
					end
				end
			end
			if (self.player:hasWeapon("blade") or self:getCardsNum("Blade") > 0) and getCardsNum("Jink", enemy) <= hit_num then return analeptic end
			if self:hasCrossbowEffect(self.player) and hit_num >= 2 then return analeptic end
		end
	end

	if weapon and (self:getCardsNum("Slash") > 0 and self:slashIsAvailable() or not SelfisCurrent) then
		local current_range = (self.player:getWeapon() and sgs.weapon_range[self.player:getWeapon():getClassName()]) or 1
		local nosuit_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local slash = SelfisCurrent and self:getCard("Slash") or nosuit_slash
		nosuit_slash:deleteLater()

		self:sort(self.enemies, "defense")

		if crossbow then
			if #self:getCards("Slash") > 1 or self:hasSkills("kurou|keji")
				or (self:hasSkills("luoshen|yongsi|luoying|guzheng|moyue") and not SelfisCurrent and self.room:alivePlayerCount() >= 4) then
				return crossbow:getEffectiveId()
			end
			if self.player:hasSkill("guixin") and self.room:alivePlayerCount() >= 6 and (self.player:getHp() > 1 or self:getCardsNum("Peach") > 0) then
				return crossbow:getEffectiveId()
			end
			if self.player:hasSkill("rende") then
				for _, friend in ipairs(self.friends_noself) do
					if getCardsNum("Slash", friend) > 1 then
						return crossbow:getEffectiveId()
					end
				end
			end
			if self:isEnemy(NextPlayer) then
				local CanSave, huanggai, zhenji
				for _, enemy in ipairs(self.enemies) do
					if enemy:hasSkill("buyi") then CanSave = true end
					if enemy:hasSkill("jijiu") and getKnownCard(enemy, self.player, "red", nil, "he") > 1 then CanSave = true end
					if enemy:hasSkill("chunlao") and enemy:getPile("wine"):length() > 1 then CanSave = true end
					if enemy:hasSkill("kurou") then huanggai = enemy end
					if enemy:hasSkill("keji") then return crossbow:getEffectiveId() end
					if self:hasSkills("luoshen|yongsi|guzheng", enemy) then return crossbow:getEffectiveId() end
					if enemy:hasSkill("luoying") and crossbow:getSuit() ~= sgs.Card_Club then return crossbow:getEffectiveId() end
					if enemy:hasSkill("moyue") then return crossbow:getEffectiveId() end
				end
				if huanggai then
					if huanggai:getHp() > 2 then return crossbow:getEffectiveId() end
					if CanSave then return crossbow:getEffectiveId() end
				end
				if getCardsNum("Slash", NextPlayer) >= 3 and NextPlayerisEnemy then return crossbow:getEffectiveId() end
			end
		end

		if halberd then
			if self.player:hasSkills("nosrende|rende") and self:findFriendsByType(sgs.Friend_Draw) then return halberd end
			if SelfisCurrent and self:getCardsNum("Slash") == 1 and self.player:getHandcardNum() == 1 then return halberd end
		end

		if gudingdao then
			local range_fix = current_range - 2
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, true, range_fix) and enemy:isKongcheng() and not enemy:hasSkill("tianming") and
				(not SelfisCurrent or (self:getCardsNum("Dismantlement") > 0 or (self:getCardsNum("Snatch") > 0 and self.player:distanceTo(enemy) == 1))) then
					return gudingdao
				end
			end
		end

		if axe then
			local range_fix = current_range - 3
			local FFFslash = self:getCard("FireSlash")
			local TTTslash = self:getCard("ThunderSlash")
			local IIIslash = self:getCard("IceSlash")
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasArmorEffect("vine") and FFFslash and self:slashIsEffective(FFFslash, enemy) and
					self.player:getCardCount(true) >= 3 and self.player:canSlash(enemy, FFFslash, true, range_fix) then
					return axe
				elseif enemy:hasArmorEffect("toujing") and TTTslash and self:slashIsEffective(TTTslash, enemy) and
					self.player:getCardCount(true) >= 3 and self.player:canSlash(enemy, TTTslash, true, range_fix) then
					return axe
				elseif self:getCardsNum("Analeptic") > 0 and self.player:getCardCount(true) >= 4 and
					self:slashIsEffective(slash, enemy) and self.player:canSlash(enemy, slash, true, range_fix) then
					return axe
				end
			end
		end

		if double then
			local range_fix = current_range - 2
			for _, enemy in ipairs(self.enemies) do
				if self.player:getGender() ~= enemy:getGender() and self.player:canSlash(enemy, nil, true, range_fix) then
					return double
				end
			end
		end

		if qinggang then
			local range_fix = current_range - 2
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, true, range_fix) and self:slashIsEffective(slash, enemy, self.player, true) then
					return qinggang
				end
			end
		end
		
		if spmoonspear then
			local range_fix = current_range - 3
			if self.player:hasSkills("xingyi|yunyao|yueying|yuechao|guanxi") then
				return spmoonspear
			end
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasSkills("xingyi|yunyao|yueying|yuechao|guanxi") then
					return spmoonspear
				end
			end
		end
	end

	local snatch, dismantlement, indulgence, supplyshortage, collateral, duel, aoe, ironchain, godsalvation, fireattack, lightning
	local new_enemies = {}
	if #self.enemies > 0 then new_enemies = self.enemies
	else
		for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if sgs.evaluatePlayerRole(aplayer) == "neutral" then
				table.insert(new_enemies, aplayer)
			end
		end
	end
	for _, card in ipairs(cards) do
		for _, enemy in ipairs(new_enemies) do
			if card:isKindOf("Snatch") and self:hasTrickEffective(card, enemy, self.player) and self.player:distanceTo(enemy) == 1 and not enemy:isNude() then
				snatch = card:getEffectiveId()
			elseif not enemy:isNude() and card:isKindOf("Dismantlement") and self:hasTrickEffective(card, enemy, self.player) then
				dismantlement = card:getEffectiveId()
			elseif card:isKindOf("Indulgence") and self:hasTrickEffective(card, enemy, self.player) and not enemy:containsTrick("indulgence") then
				indulgence = card:getEffectiveId()
			elseif card:isKindOf("SupplyShortage")  and self:hasTrickEffective(card, enemy, self.player) and not enemy:containsTrick("supply_shortage") then
				supplyshortage = card:getEffectiveId()
			elseif card:isKindOf("Collateral") and self:hasTrickEffective(card, enemy, self.player) and enemy:getWeapon() then
				collateral = card:getEffectiveId()
			elseif card:isKindOf("Duel") and self:hasTrickEffective(card, enemy, self.player) and
					(self:getCardsNum("Slash") >= getCardsNum("Slash", enemy, self.player) or self.player:getHandcardNum() > 4) then
				duel = card:getEffectiveId()
			elseif card:isKindOf("AOE") then
				local dummy_use = {isDummy = true}
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then
					aoe = card:getEffectiveId()
				end
			elseif card:isKindOf("IronChain") then
				local dummy_use = {isDummy = true}
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then
					ironchain = card:getEffectiveId()
				end
			elseif card:isKindOf("FireAttack") and self:hasTrickEffective(card, enemy, self.player) then
				local FFF
				local jinxuandi = self.room:findPlayerBySkillName("wuling")
				if jinxuandi and jinxuandi:getMark("@fire") > 0 then FFF = true end
				if self.player:hasSkill("shaoying") then FFF = true end
				if enemy:getHp() == 1 or enemy:hasArmorEffect("vine") or enemy:getMark("@gale") > 0 then FFF = true end
				if FFF then
					local suits= {}
					local suitnum = 0
					for _, hcard in sgs.qlist(self.player:getHandcards()) do
						if hcard:getSuit() == sgs.Card_Spade then
							suits.spade = true
						elseif hcard:getSuit() == sgs.Card_Heart then
							suits.heart = true
						elseif hcard:getSuit() == sgs.Card_Club then
							suits.club = true
						elseif hcard:getSuit() == sgs.Card_Diamond then
							suits.diamond = true
						end
					end
					for k, hassuit in pairs(suits) do
						if hassuit then suitnum = suitnum + 1 end
					end
					if suitnum >= 3 or (suitnum >= 2 and enemy:getHandcardNum() == 1 ) then
						fireattack = card:getEffectiveId()
					end
				end
			elseif card:isKindOf("GodSalvation") and self:willUseGodSalvation(card) then
				godsalvation = card:getEffectiveId()
			elseif card:isKindOf("Lightning") and self:getFinalRetrial() == 1 then
				lightning = card:getEffectiveId()
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if (self:hasTrickEffective(card, friend) and (self:willSkipPlayPhase(friend, true) or self:willSkipDrawPhase(friend, true))) or
				self:needToThrowArmor(friend) then
				if isCard("Snatch", card, self.player) and self.player:distanceTo(friend) == 1 then
					snatch = card:getEffectiveId()
				elseif isCard("Dismantlement", card, self.player) then
					dismantlement = card:getEffectiveId()
				end
			end
		end
	end

	if snatch or dismantlement or indulgence or supplyshortage or collateral or duel or aoe or ironchain or godsalvation or fireattack or lightning then
		if not self:willSkipPlayPhase() or not NextPlayerCanUse then
			return snatch or dismantlement or indulgence or supplyshortage or collateral or duel or aoe or ironchain or godsalvation or fireattack or lightning
		end
		if #trickcard > nextfriend_num + 1 and NextPlayerCanUse then
			return lightning or fireattack or godsalvation or aoe or duel or ironchain or collateral or supplyshortage or indulgence or dismantlement or snatch
		end
	end

	if weapon and not self.player:getWeapon() and self:getCardsNum("Slash") > 0 and (self:slashIsAvailable() or not SelfisCurrent) then
		local inAttackRange
		for _, enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) then
				inAttackRange = true
				break
			end
		end
		if not inAttackRange then return weapon end
	end

	self:sortByCardNeed(cards, true)
	for _, card in ipairs(cards) do
		if not card:isKindOf("TrickCard") and not card:isKindOf("Peach") then
			return card:getEffectiveId()
		end
	end

	return cards[1]:getEffectiveId()
end

--WoodenOx
local wooden_ox_skill = {}
wooden_ox_skill.name = "wooden_ox"
table.insert(sgs.ai_skills, wooden_ox_skill)
wooden_ox_skill.getTurnUseCard = function(self)
	if self.player:hasSkills(sgs.lose_equip_skill) then sgs.ai_use_priority.WoodenOxCard = 7 end
	self.wooden_ox_assist = nil
	if self.player:hasUsed("WoodenOxCard") or self.player:isKongcheng() or not self.player:hasTreasure("wooden_ox") then return end
	
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
	until nextAlive:faceUp()

	if self.player:getRole() == "lord" and self:isWeak() and self:getOverflow() > 0 and self:isEnemy(nextAlive) and not self.player:hasSkills("yongsi|olyongsi") then
		self.wooden_ox_assist = nil
		return sgs.Card_Parse("@WoodenOxCard=" .. cards[1]:getEffectiveId())
	end
	
	if self.player:getRole() == "loyalist" and self:isWeak(self.room:getLord()) then
		self.wooden_ox_assist = self.room:getLord()
		local to_lord_cards = {}
		for _,c in ipairs(cards) do
			if c:isKindOf("Jink") or c:isKindOf("Analeptic") then
				table.insert(to_lord_cards, c)
			end
		end
		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				if sgs.Sanguosha:getCard(id):isKindOf("Jink") or sgs.Sanguosha:getCard(id):isKindOf("Analeptic") then
					return sgs.Card_Parse("@WoodenOxCard=" .. cards[1]:getEffectiveId())
				end
			end
		end
		if #to_lord_cards > 0 then
			return sgs.Card_Parse("@WoodenOxCard=" .. to_lord_cards[1]:getEffectiveId())
		end
	end
	
	self:updatePlayers()
	self:sort(self.friends_noself, "defense")
	local nextAliveFriend = self.player
	if #self.friends_noself > 0 then
		repeat
			nextAliveFriend = nextAliveFriend:getNextAlive()
		until nextAliveFriend:faceUp() and self:isFriend(nextAliveFriend)
	end
	
	if self.room:getMode() == "06_ol" and #self.enemies == 1 and #self.friends_noself > 0 then
		self.wooden_ox_assist = nextAliveFriend
		for _,c in ipairs(cards) do
			if c:isKindOf("Crossbow") or (c:isKindOf("GodNihilo") and self:DoNotUseofGodNihilo()) then
				return sgs.Card_Parse("@WoodenOxCard=" .. c:getEffectiveId())
			end
		end
		if self:getCardsNum("Slash") > 0 then
			for _,c in ipairs(cards) do
				if c:isKindOf("Slash") then
					return sgs.Card_Parse("@WoodenOxCard=" .. c:getEffectiveId())
				end
			end
		end
		for _,c in ipairs(cards) do
			if not c:isKindOf("Lightning") then
				return sgs.Card_Parse("@WoodenOxCard=" .. c:getEffectiveId())
			end
		end
	end
	
	if self.player:hasSkill("xiaoji") then
		self.wooden_ox_assist = nextAliveFriend
		for _,c in ipairs(cards) do
			return sgs.Card_Parse("@WoodenOxCard=" .. c:getEffectiveId())
		end
	end
	
	local card, friend = self:getCardNeedPlayer(cards)
	if card and friend and friend:objectName() ~= self.player:objectName() and (self:getOverflow() > 0 or self.player:getHandcardNum() > 2 or self:isWeak(friend)) then
		self.wooden_ox_assist = friend
		return sgs.Card_Parse("@WoodenOxCard=" .. card:getEffectiveId())
	end
	if (self:getOverflow() > 0 or (self:needKongcheng() and #cards == 1)) and not self.player:hasSkills("yongsi|olyongsi")  then
		self.wooden_ox_assist = nil
		return sgs.Card_Parse("@WoodenOxCard=" .. cards[1]:getEffectiveId())
	end
end

sgs.ai_skill_use_func.WoodenOxCard = function(card, use, self)
	use.card = card
end

sgs.ai_skill_playerchosen.wooden_ox = function(self, targets)
	return self.wooden_ox_assist
end

sgs.ai_playerchosen_intention.wooden_ox = -10

sgs.ai_use_priority.WoodenOxCard = 0

function SmartAI:useCardFudichouxin(card, use)
	--if self.room:isProhibited(self.player, self.player, card) then return end
	
    function filluse(to, id)
        use.card = card
        if (use.to) then use.to:append(to) end
    end

    local l = {}
    function calculateHandcardnum(player)
		local X = player:getHandcardNum()
		if not hasManjuanEffect(player) then
			X = X + player:getEquips():length()
			if player:hasSkills("xiaoji") then
				X = X + player:getEquips():length() * 2
			end
		end
		return X
    end
	
	--出牌阶段内优先抽自己的情况
	if (self.player:hasSkills("shuoyi|xixue") or self.player:getMark("&motiao_using") > 0) and self.player:getPhase() == sgs.Player_Play and not self.player:getEquips():isEmpty() and not self.room:isProhibited(self.player, self.player, card) and not self:isEquipLocking(self.player) then
		filluse(self.player, nil)
		return
	end

    self:sort(self.friends, "defense")
	
    for _, p in ipairs(self.friends) do
        if (self:needToThrowArmor(p) and p:getArmor()) and not self.room:isProhibited(self.player, p, card) and not self:isEquipLocking(p) then
            filluse(p, p:getArmor():getEffectiveId())
            return
        end
    end
--[[
    for _, p in ipairs(self.enemies) do
        if calculateHandcardnum(p) <= p:getHp() and not p:hasSkills(sgs.lose_equip_skill) and not (self:needToThrowArmor(p)) then
			local value = 0
			if p:hasSkills(sgs.need_equip_skill) or hasManjuanEffect(p) then
				value = value + 2
			end
			if self:needKongcheng(p) and p:isKongcheng() and not hasManjuanEffect(p) then
				value = value + 3
			end
			if self:willSkipPlayPhase(p) then
				value = value + 1
			end
			table.insert(l, {player = p, id = -1, minus = value})
        end
    end

    for _, p in ipairs(self.friends) do
        if calculateHandcardnum(p) <= p:getHp() and ((p:hasSkills(sgs.lose_equip_skill) and not hasManjuanEffect(p)) and not p:hasSkills(sgs.need_equip_skill)) or self:needToThrowArmor(p) then
			local value = 10
			if p:hasSkills(sgs.need_equip_skill) or hasManjuanEffect(p) then
				value = value - 2
			end
			if self:needKongcheng(p) and p:isKongcheng() and not hasManjuanEffect(p) then
				value = value - 3
			end
			if self:willSkipPlayPhase(p) then
				value = value - 1
			end
            table.insert(l, {player = p, id = -1, minus = value})
		elseif self:needToThrowArmor(p) then
			table.insert(l, {player = p, id = -1, minus = 8})
        end
    end

    if #l > 0 then
        function sortByMinus(a, b)
            return a.minus > b.minus
        end

        table.sort(l, sortByMinus)
        if l[1].player:getEquips():length() > 0 and not self.room:isProhibited(self.player, l[1].player, card) then
            filluse(l[1].player, l[1].id)
            return
        end
    end
]]
    self:sort(self.enemies, "threat")
	
    for _, p in ipairs(self.enemies) do
        if (p:getTreasure() and (p:getTreasure():isKindOf("Lianglunche") or p:getPile("wooden_ox"):length() >= 1 or p:getPile("cangbaotu_pile"):length() >= 1)) and not p:hasSkills(sgs.lose_equip_skill) and not self.room:isProhibited(self.player, p, card) then
            filluse(p, p:getTreasure():getEffectiveId())
            return
        end
    end

    for _, p in ipairs(self.enemies) do
        if self:needKongcheng(p) and p:isKongcheng() and not hasManjuanEffect(p) and p:getEquips():length() > 0 and not self.room:isProhibited(self.player, p, card) and not self:isEquipLocking(p) then
            filluse(p, -1)
            return
        end
    end

    for _, p in ipairs(self.enemies) do
        if ((self:willSkipPlayPhase(p) and self:getOverflow(p) + p:getEquips():length() > 0) or (hasManjuanEffect(p))) and p:getEquips():length() > 0 and not self.room:isProhibited(self.player, p, card) and not self:isEquipLocking(p) then
            filluse(p, -1)
            return
        end
    end

    for _, p in ipairs(self.enemies) do
        if (p:getArmor() and not p:getArmor():isKindOf("GaleShell")) and not self.room:isProhibited(self.player, p, card) and not self:isEquipLocking(p) then
            filluse(p, p:getArmor():getEffectiveId())
            return
        end
    end

    for _, p in ipairs(self.enemies) do
        if (p:getDefensiveHorse()) and not self.room:isProhibited(self.player, p, card) and not self:isEquipLocking(p) then
            filluse(p, p:getDefensiveHorse():getEffectiveId())
            return
        end
    end

    for _, p in ipairs(self.friends) do
        if p:hasSkills(sgs.lose_equip_skill) and p:getEquips():length() > 0 and not self:willSkipPlayPhase(p) and not self.room:isProhibited(self.player, p, card) and not self:isEquipLocking(p) then
            filluse(p, p:getCards("e"):first():getEffectiveId())
            return
        end
    end
	
	--需要用牌就随便找个人用了
	if self.player:hasSkills(sgs.need_kongcheng.."|shuoyi|xixue|motiao|zhanshu|zhuoshi|jiezhi_zl") or self:needKongcheng() or self.player:getHandcardNum() > self:getBestKeepHandcardNum(self.player, 999) then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if not p:getEquips():isEmpty() and not self.room:isProhibited(self.player, p, card) then
				filluse(p, -1)
				return
			end
		end
	end
	return
end

sgs.ai_use_value.Fudichouxin = 3.6
sgs.ai_use_priority.Fudichouxin = sgs.ai_use_priority.Snatch - 0.1
sgs.ai_keep_value.Fudichouxin = 2.2

sgs.dynamic_value.control_card.Fudichouxin = true



sgs.ai_skill_use_func.Yuhangtu = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.Yuhangtu = 0



sgs.ai_skill_use_func.Lianglunche = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.Lianglunche = 0



sgs.ai_skill_use_func.Cangbaotu = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.Cangbaotu = -0.1


function SmartAI:useCardBefriendAttacking(card, use)
	--if self.room:isProhibited(self.player, self.player, card) then return end
	
    function filluse(to)
        use.card = card
        if (use.to) then use.to:append(to) end
    end

    self:sort(self.enemies, "threat")
	
    for _, p in ipairs(self.enemies) do		--对有CP的需要对其造成伤害的敌方角色使用，或对不能摸牌的敌方角色使用
		local cp = p:getTag("spouse"):toPlayer()
        if cp and cp:isAlive() and (self:isWeak(p) or not self:canDraw(cp)) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player, card) and not self.room:isProhibited(self.player, cp, card) then
            filluse(cp)
            return
        end
    end

    self:sort(self.friends_noself, "defense")
	
    for _, p in ipairs(self.friends_noself) do		--对无CP/CP需要卖血/CP血量充足/CP免伤的友方角色使用
		local cp = p:getTag("spouse"):toPlayer()
        if (not cp or cp:isDead() or self:needToLoseHp(cp) or ((cp:hasSkills(sgs.masochism_skill) or cp:getHp() >= 5 or not self:damageIsEffective(cp, sgs.DamageStruct_Normal, self.player, card)) and not self:isWeak(cp))) and self:canDraw(p) and not self.room:isProhibited(self.player, p, card) then
            filluse(p)
            return
        end
    end
	
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do	--对落单角色或不能摸牌的敌方角色使用
		local cp = p:getTag("spouse"):toPlayer()
        if (not cp or cp:isDead()) and (not self:isEnemy(p) or not self:canDraw(p)) and not self.room:isProhibited(self.player, p, card) then
            filluse(p)
            return
        end
	end
	
	return
end

sgs.ai_use_value.BefriendAttacking = 4
sgs.ai_use_priority.BefriendAttacking = sgs.ai_use_priority.Snatch - 0.1
sgs.ai_keep_value.BefriendAttacking = 1

sgs.dynamic_value.damage_card.BefriendAttacking = true

