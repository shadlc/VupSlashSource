
function getTurnUse(self)
    local cards = {}
    for _ ,c in sgs.qlist(self.player:getHandcards()) do
        if c:isAvailable(self.player) then table.insert(cards, c) end
    end
    for _, id in sgs.qlist(self.player:getHandPile()) do
        local c = sgs.Sanguosha:getCard(id)
        if c:isAvailable(self.player) then table.insert(cards, c) end
    end
    if self.player:hasSkill("taoxi") and self.player:hasFlag("TaoxiRecord") then
        local taoxi_id = self.player:getTag("TaoxiId"):toInt()
        if taoxi_id and taoxi_id >= 0 then
            local taoxi_card = sgs.Sanguosha:getCard(taoxi_id)
            table.insert(cards, taoxi_card)
        end
    end
	
    local turnUse = {}
    local slash = sgs.Sanguosha:cloneCard("slash")
    local slashAvail = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash)
    self.slashAvail = slashAvail
    self.predictedRange = self.player:getAttackRange()
    self.slash_distance_limit = (1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50)
	slash:deleteLater()

    self.weaponUsed = false
	--self:fillSkillCards(cards) 万恶的无限循环！！！！！
    self:sortByUseValue(cards)

    if self.player:hasWeapon("crossbow") or #self.player:property("extra_slash_specific_assignee"):toString():split("+") > 1 then
        slashAvail = 100
        self.slashAvail = slashAvail
    elseif self.player:hasWeapon("vscrossbow") then
        slashAvail = slashAvail + 3
        self.slashAvail = slashAvail
    end

    for _, card in ipairs(cards) do
        local dummy_use = { isDummy = true }

        local type = card:getTypeId()
        self["use" .. sgs.ai_type_name[type + 1] .. "Card"](self, card, dummy_use)

        if dummy_use.card then
            if dummy_use.card:isKindOf("Slash") then
                if slashAvail > 0 then
                    slashAvail = slashAvail - 1
                    table.insert(turnUse, dummy_use.card)
                elseif dummy_use.card:hasFlag("AIGlobal_KillOff") then table.insert(turnUse, dummy_use.card) end
            else
                if self.player:hasFlag("InfinityAttackRange") or self.player:getMark("InfinityAttackRange") > 0 then
                    self.predictedRange = 10000
                elseif dummy_use.card:isKindOf("Weapon") then
                    self.predictedRange = sgs.weapon_range[card:getClassName()]
                    self.weaponUsed = true
                else
                    self.predictedRange = 1
                end
                if dummy_use.card:objectName() == "Crossbow" then slashAvail = 100 self.slashAvail = slashAvail end
                if dummy_use.card:objectName() == "VSCrossbow" then slashAvail = slashAvail + 3 self.slashAvail = slashAvail end
                table.insert(turnUse, dummy_use.card)
            end
        end
    end

    return turnUse
end

function willUse(self, className)--感谢敢达杀作者饺神wch鸽的无私奉献
	for _,card in ipairs(getTurnUse(self)) do
		if card:isKindOf(className) then
			return true
		end
	end
	return false
end

function SmartAI:useCardThunderSlash(...)
	self:useCardSlash(...)
end

sgs.ai_card_intention.ThunderSlash = sgs.ai_card_intention.Slash

sgs.ai_use_value.ThunderSlash = 4.55
sgs.ai_keep_value.ThunderSlash = 3.66
sgs.ai_use_priority.ThunderSlash = 2.5

function SmartAI:useCardFireSlash(...)
	self:useCardSlash(...)
end

sgs.ai_card_intention.FireSlash = sgs.ai_card_intention.Slash

sgs.ai_use_value.FireSlash = 4.6
sgs.ai_keep_value.FireSlash = 3.63
sgs.ai_use_priority.FireSlash = 2.5

function SmartAI:useCardIceSlash(...)
	self.is_ice_slash = true
	self:useCardSlash(...)
	self.is_ice_slash = false
end

sgs.ai_card_intention.IceSlash = sgs.ai_card_intention.Slash

sgs.ai_use_value.IceSlash = 4.6
sgs.ai_keep_value.IceSlash = 3.67
sgs.ai_use_priority.IceSlash = 2.5

sgs.weapon_range.Fan = 4
sgs.ai_use_priority.Fan = 2.655
--sgs.ai_use_priority.Vine = 0.95
sgs.ai_use_priority.Vine = 0.75

sgs.ai_skill_invoke.fan = function(self, data)
	local use = data:toCardUse()
	local jinxuandi = self.room:findPlayerBySkillName("wuling")

	for _, target in sgs.qlist(use.to) do
		if self:isFriend(target) then
			if not self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) then return true end
			if target:isChained() and self:isGoodChainTarget(target, nil, nil, nil, use.card) then return true end
		else
			if not self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) then return false end
			if target:isChained() and not self:isGoodChainTarget(target, nil, nil, nil, use.card) then return false end
			if target:hasArmorEffect("vine") or target:getMark("@gale") > 0 or (jinxuandi and jinxuandi:getMark("@wind") > 0) then
				return true
			end
		end
	end
	return false
end
sgs.ai_view_as.fan = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		and card_place ~= sgs.Player_PlaceSpecial and card:objectName() == "slash" then
		return ("fire_slash:fan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local fan_skill={}
fan_skill.name="fan"
table.insert(sgs.ai_skills,fan_skill)
fan_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	local slash_card

	for _,card in ipairs(cards)  do
		if card:isKindOf("Slash") and not (card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash")) then
			slash_card = card
			break
		end
	end

	if not slash_card  then return nil end
	local suit = slash_card:getSuitString()
	local number = slash_card:getNumberString()
	local card_id = slash_card:getEffectiveId()
	local card_str = ("fire_slash:fan[%s:%s]=%d"):format(suit, number, card_id)
	local fireslash = sgs.Card_Parse(card_str)
	assert(fireslash)

	return fireslash

end

function sgs.ai_weapon_value.fan(self, enemy)
	if enemy and (enemy:hasArmorEffect("vine") or enemy:getMark("@gale") > 0) then return 6 end
end

function sgs.ai_armor_value.vine(player, self)
	if self:needKongcheng(player) and player:getHandcardNum() == 1 then
		return player:hasSkill("kongcheng") and 5 or 3.8
	end
	if self:hasSkills(sgs.lose_equip_skill, player) then return 3.8 end
	if self:hasSkills("motiao", player) and not self:isWeak(player) then return 3.8 end
	if not self:damageIsEffective(player, sgs.DamageStruct_Fire) then return 6 end
	if self.player:hasSkill("sizhan") then return 4.9 end
	if player:hasSkill("jujian") and not player:getArmor() and #(self:getFriendsNoself(player)) > 0 and player:getPhase() == sgs.Player_Play then return 3 end
	if player:hasSkill("diyyicong") and not player:getArmor() and player:getPhase() == sgs.Player_Play then return 3 end

	if sgs.turncount <= 1 and #self.enemies > 1 then return -2 end

	local fslash = sgs.Sanguosha:cloneCard("fire_slash")
	local tslash = sgs.Sanguosha:cloneCard("thunder_slash")
	if player:isChained() and (not self:isGoodChainTarget(player, self.player, nil, nil, fslash) or not self:isGoodChainTarget(player, self.player, nil, nil, tslash)) then
		fslash:deleteLater()
		tslash:deleteLater()
		return -2
	end
	fslash:deleteLater()
	tslash:deleteLater()

	for _, enemy in ipairs(self:getEnemies(player)) do
		if (enemy:canSlash(player) and enemy:hasWeapon("fan")) or enemy:hasSkills("huoji|longhun|new_longhun|shaoying|zonghuo|wuling|ol_xueji|pingcai|longnu|jianjie|ol_rende|yizan|quanneng|fenxin")
		  or (enemy:hasSkill("yeyan") and enemy:getMark("@flame") > 0)
		  or (enemy:hasSkill("zhanhuo") and enemy:getMark("@fire_boom") > 0)
		  or (enemy:hasSkill("zhanhuo_sec_rev") and enemy:getMark("@fire_boom_sec_rev") > 0)
		  or (enemy:getMark("@dragon") > 0 and self.room:findPlayerBySkillName("jianjie")) then return -2 end
		if getKnownCard(enemy, player, "FireSlash", true) >= 1 or getKnownCard(enemy, player, "FireAttack", true) >= 1 or
			getKnownCard(enemy, player, "fan") >= 1 then return -2 end
	end

	if (#self.enemies < 3 and sgs.turncount > 2) or player:getHp() <= 2 then return 5 end
	if player:hasSkill("xiansi") and player:getPile("counter"):length() > 1 then return 3 end
	return 0.1
end

function SmartAI:shouldUseAnaleptic(target, slash)
	if sgs.turncount <= 1 and self.role == "renegade" and sgs.isLordHealthy() and self:getOverflow() < 2 then return false end
	if target:hasArmorEffect("silver_lion") and not (IgnoreArmor(self.player, target) or self.player:hasSkill("jueqing")) then
		return false
	end
	if self.player:getMark("drank") > 0 then return false end
	
	--考慮可能酒元素殺鐵鎖中的隊友
	if not self:isGoodChainTarget(target, self.player, nil, 2) and slash:isKindOf("NatureSlash") then return false end
	--丈八一張酒和一張非殺的情況不要用酒
	local real_slash_num = 0
	if self.player:getWeapon() and self.player:getWeapon():isKindOf("Spear") then
		for _, c in sgs.qlist(self.player:getCards("h")) do
			if c:isKindOf("Slash") then
				real_slash_num = real_slash_num + 1
			end
		end
		if real_slash_num <= 0 then
			return false
		end
	end
	
	--1血目标有宇航兔
	if target:getTreasure() and target:getTreasure():isKindOf("Yuhangtu") and target:getHp() <= 1 then
		return false
	end
	--目标有离诀
	if target:hasSkills("lijue_akane") then
		return false
	end
	--目标空城且有阴憩
	if target:hasSkills("yinqi") and target:isKongcheng() then
		return false
	end
	
	--J.SP馬超刺槐
	if self.player:getMark("@cihuai") > 0 and self:getCardsNum("Slash") == 0 then
		return false
	end
	--橘標記
	local luji = self.room:findPlayerBySkillName("huaiju")
	if luji and target:getMark("@orange") > 0 then return false end
	--卫境用酒情況
	if target:hasSkill("weijing") and target:getMark("weijing_lun") == 0 then return false end
	--翊贊用酒情況
	local yizan_real_analeptic_num = 0
	if self.player:hasSkill("yizan") then
		for _, c in sgs.qlist(self.player:getCards("h")) do
			if c:isKindOf("Analeptic") then
				yizan_real_analeptic_num = yizan_real_analeptic_num + 1
			end
		end
		if yizan_real_analeptic_num <= 0 then
			return false
		end
	end
	--自身虛弱且無閃和桃不用酒
	if self:isWeak() and self:getCardsNum("Jink") + self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 1 and not self.player:hasSkill("kongcheng") then return false end
	--守璽不用酒
	local shouxi_mark_count = 0
	for _, mark in sgs.list(target:getMarkNames()) do
		if string.find(mark, "shouxi") then
			shouxi_mark_count = shouxi_mark_count + 1
		end
	end
	if target:hasSkill("shouxi") and shouxi_mark_count < 10 then return false end
	--諸葛瞻-第二版父蔭不用酒
	if target:hasSkill("fuyin_sec_rev") and self.player:getHandcardNum() >= target:getHandcardNum() and target:getMark("fuyin_sec_rev-Clear") == 0 then return false end
	--來源攻擊範圍小於3不對潘濬用酒
	if self.player:getAttackRange() < 3 and target:hasSkill("gongqing") then return false end
	--沒攻擊範圍往烈不用酒
	local wanglie_has_slash_enemy = false
	for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash, false) and not self:slashProhibit(slash, enemy) and self.player:inMyAttackRange(enemy)
		and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
			wanglie_has_slash_enemy = true
		end
	end
	if self.player:hasSkill("wanglie") and self.player:getMark("used_Play") == 0 and not wanglie_has_slash_enemy then return false end
	--于吉-國敵人有"幻"不用酒
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("qianhuan") and  enemy:getPile("sorcery"):length() > 0 then
			return false
		end
	end
	--殘蝕剩一張殺不用酒
	if self.player:hasSkill("canshi") and self.player:hasFlag("canshi") then
		--有仇海
		if self.player:hasSkill("chouhai") and self.player:getHandcardNum() <= 4 then
			return false
		end
		--有仇海不要酒殺賄生
		if self.player:hasSkill("chouhai") and target:hasSkill("huisheng") and self.player:getMark("@huisheng") == 0 then
			return false
		end
		--無仇海
		if not self.player:hasSkill("chouhai") and self:getCardsNum("Slash") <= 1 then
			return false
		end
	end
	--雷包庸肆
	if self.player:hasSkill("god_yongsi") and self.player:getLostHp() == 0 then return false end
	
	if target:hasSkill("zhenlie") then return false end
	if target:hasSkill("xiangle") then
		local basicnum = 0
		for _, acard in sgs.qlist(self.player:getHandcards()) do
			if acard:getTypeId() == sgs.Card_TypeBasic and not acard:isKindOf("Peach") then basicnum = basicnum + 1 end
		end
		if basicnum < 3 then return false end
	end
	if self.player:hasSkill("canshi") and self.player:hasFlag("canshi") and self.player:getHandcardNum() < 3 then return false end

	if self:hasSkills(sgs.masochism_skill .. "|longhun|buqu|nosbuqu|" .. sgs.recover_skill, target)
		and self.player:hasSkill("nosqianxi") and self.player:distanceTo(target) == 1 then
		return
	end

	local hcard = target:getHandcardNum()
	if self.player:hasSkill("liegong") and self.player:getPhase() == sgs.Player_Play and (hcard >= self.player:getHp() or hcard <= self.player:getAttackRange()) then return true end
	if self.player:hasSkill("kofliegong") and self.player:getPhase() == sgs.Player_Play and hcard >= self.player:getHp() then return true end
	if self.player:hasSkill("tieji") then return true end
	
	--排除以上狀況後，有攻擊範圍往烈用酒
	if self.player:hasSkill("wanglie") and self.player:getMark("used_Play") == 0 and wanglie_has_slash_enemy then return true end

	if self.player:hasWeapon("axe") and self.player:getCards("he"):length() > 4 then return true end
	if target:hasFlag("dahe") then return true end

	if ((self.player:hasSkill("roulin") and target:isFemale()) or (self.player:isFemale() and target:hasSkill("roulin"))) or self.player:hasSkill("wushuang") then
		if getKnownCard(target, player, "Jink", true, "he") >= 2 then return false end
		return getCardsNum("Jink", target, self.player) < 2
	end

	if getKnownCard(target, self.player, "Jink", true, "he") >= 1 and not (self:getOverflow() > 0 and self:getCardsNum("Analeptic") > 1) then return false end
	return self:getCardsNum("Analeptic") > 1 or getCardsNum("Jink", target) < 1 or sgs.card_lack[target:objectName()]["Jink"] == 1 or self:getOverflow() > 0
end

function SmartAI:willUseAnalepticSlash(player, slash, ignoreDistance)	--返回是否有适合酒杀的目标
	local ignoreDistance = false
	local enemies = self:getEnemies(player)
	for _,to in ipairs(enemies) do
		if player:canSlash(to, slash, not ignoreDistance) and self:slashIsEffective(slash, to, player) and sgs.isGoodTarget(to, enemies, self, true) 
			and not self:slashProhibit(slash, to, player) and self:shouldUseAnaleptic(to, slash) then
				return true
		end
	end
	return false
end

function SmartAI:justUseAnaleptic(player)	--为虚拟杀提供酒杀接口
	player = player or self.player
	if player:hasSkill("qilv") then		--奇虑，最后一张将用锦囊之前用酒
		local will_use_count = 0
		for _,cd in sgs.qlist(player:getHandcards()) do
			if cd:isKindOf("TrickCard") and self:willUse(player, cd, false, false, true) then
				will_use_count = will_use_count + 1
			end
		end
		if will_use_count == 1 then
			local virtual_slash = sgs.Sanguosha:cloneCard("slash")
			local result = self:willUseAnalepticSlash(player, virtual_slash, false)
			virtual_slash:deleteLater()
			return result
		end
	end
	return false
end

function SmartAI:useCardAnaleptic(card, use)
	
	--有營的標記下不留酒
	if not self.player:hasEquip(card) and sgs.Analeptic_IsAvailable(self.player, card)
	and self.player:getMark("@thiefed") > 0 and not self.player:hasSkill("jieyingy") and self.room:findPlayerBySkillName("jieyingy")
	then
		use.card = card
	end
	
	if not self.player:hasEquip(card) and (not self:hasLoseHandcardEffective() or self:justUseAnaleptic()) and not self:isWeak()
		and sgs.Analeptic_IsAvailable(self.player, card) then
		use.card = card
	end
end

function SmartAI:searchForAnaleptic(use, enemy, slash)
	if not self.toUse then return nil end
	if not use.to then return nil end

	local analeptic = self:getCard("Analeptic")
	if not analeptic then return nil end

	local analepticAvail = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, analeptic)
	local slashAvail = 0

	for _, card in ipairs(self.toUse) do
		if analepticAvail == 1 and card:getEffectiveId() ~= slash:getEffectiveId() and card:isKindOf("Slash") then return nil end
		if card:isKindOf("Slash") then slashAvail = slashAvail + 1 end
	end

	if analepticAvail > 1 and analepticAvail < slashAvail then return nil end
	if not sgs.Analeptic_IsAvailable(self.player) then return nil end
	for _, p in sgs.qlist(use.to) do
		if p:hasSkill("zhenlie") then return end
		if p:hasSkill("anxian") and not p:isKongcheng() and self:getOverflow() < 0 then return end
	end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:fillSkillCards(cards)
	local allcards = self.player:getCards("he")
	allcards = sgs.QList2Table(allcards)

	if self.player:getPhase() == sgs.Player_Play then
		if self.player:hasFlag("lexue") then
			local lexuesrc = sgs.Sanguosha:getCard(self.player:getMark("lexue"))
			if lexuesrc:isKindOf("Analeptic") then
				local cards = sgs.QList2Table(self.player:getHandcards())
				self:sortByUseValue(cards, true)
				for _, hcard in ipairs(cards) do
					if hcard:getSuit() == lexuesrc:getSuit() then
						local lexue = sgs.Sanguosha:cloneCard("analeptic", lexuesrc:getSuit(), lexuesrc:getNumber())
						lexue:addSubcard(hcard:getId())
						lexue:setSkillName("lexue")
						if self:getUseValue(lexuesrc) > self:getUseValue(hcard) then
							lexue:deleteLater()
							return lexue
						end
						lexue:deleteLater()
					end
				end
			end
		end

		if self.player:hasLordSkill("weidai") and not self.player:hasFlag("Global_WeidaiFailed") then
			return sgs.Card_Parse("@WeidaiCard=.")
		end
	end

	local card_str = self:getCardId("Analeptic")
	if card_str then return sgs.Card_Parse(card_str) end

	for _, anal in ipairs(cards) do
		if (anal:getClassName() == "Analeptic") and not (anal:getEffectiveId() == slash:getEffectiveId()) then
			return anal
		end
	end
end

sgs.dynamic_value.benefit.Analeptic = true

sgs.ai_use_value.Analeptic = 5.98
sgs.ai_keep_value.Analeptic = 4.1
sgs.ai_use_priority.Analeptic = 3.0

local function handcard_subtract_hp(a, b)
	local diff1 = a:getHandcardNum() - a:getHp()
	local diff2 = b:getHandcardNum() - b:getHp()

	return diff1 < diff2
end

function SmartAI:useCardSupplyShortage(card, use)
	local enemies = self:exclude(self.enemies, card)

	if self.player:hasSkill("ol_duanliang") then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHandcardNum() >= self.player:getHandcardNum() and not table.contains(enemies, enemy) then
				table.insert(enemies, enemy)
			end
		end
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
		if enemy:containsTrick("supply_shortage") or enemy:containsTrick("YanxiaoCard") then return -100 end
		if enemy:getMark("juao") > 0 then return -100 end
		if enemy:hasSkills("qiaobian|fahun") and not enemy:containsTrick("supply_shortage") and not enemy:containsTrick("indulgence") then return -100 end
		if zhanghe_seat > 0 and (self:playerGetRound(zhanghe) <= self:playerGetRound(enemy) and self:enemiesContainsTrick() <= 1 or not enemy:faceUp()) then
			return -100 end
		
		if enemy:hasSkill("ol_jiewei") and not enemy:faceUp() and not enemy:isNude() and not enemy:containsTrick("supply_shortage") and not enemy:containsTrick("indulgence") then return -100 end
		if ol_caoren_seat > 0 and (self:playerGetRound(ol_caoren) <= self:playerGetRound(enemy) and self:enemiesContainsTrick() <= 1 or not enemy:faceUp()) then
			return -100 end
		
		if yanxiao and (self:playerGetRound(sb_daqiao) <= self:playerGetRound(enemy) and self:enemiesContainsTrick(true) <= 1 or not enemy:faceUp()) then
			return -100 end

		--兵粮寸断优先级
		local value = 0 - enemy:getHandcardNum()

		if self:hasSkills("yongsi|haoshi|tuxi|noslijian|lijian|fanjian|neofanjian|dimeng|jijiu|jieyin|manjuan|beige",enemy)
		  or (enemy:hasSkill("zaiqi") and enemy:getLostHp() > 1)
			then value = value + 10
		end
		if self:hasSkills(sgs.cardneed_skill,enemy) or self:hasSkills("zhaolie|tianxiang|qinyin|yanxiao|zhaoxin|toudu|renjie",enemy)
			then value = value + 5
		end
		if self:hasSkills("yingzi|shelie|xuanhuo|buyi|jujian|jiangchi|mizhao|hongyuan|chongzhen|duoshi",enemy) then value = value + 1 end
		if enemy:hasSkill("zishou") then value = value + enemy:getLostHp() end
		--Vup杀 高优先级
		if enemy:hasSkills("yishou|chouka|wanlong|kunyao|chouzhen") then value = value + 10 end
		if enemy:hasSkills("xuechi|quanneng|shuoyi|zhuoshi|yuejian_akane|bingsha|liucai") then value = value + 5 end
		if enemy:hasSkills("bianshi|yueying|jinzhou|moyu|jichi|jiyue") then value = value + 3 end
		
		if self:isWeak(enemy) then value = value + 5 end
		if enemy:isLord() then value = value + 3 end

		--Vup杀 负优先级
		if enemy:hasSkills("liuyi|xuxiang") then value = value - 5 end
		if enemy:hasSkills("mingdao|zhulie|zuoye|ciyuangongzhen|yongning|mengjian") then value = value - 3 end
		
		if self:objectiveLevel(enemy) < 3 then value = value - 10 end
		if not enemy:faceUp() then value = value - 10 end
		if self:hasSkills("keji|shensu|qingyi", enemy) then value = value - enemy:getHandcardNum() end
		if self:hasSkills("guanxing|xiuluo|tiandu|guidao|noszhenlie", enemy) then value = value - 5 end
		if not sgs.isGoodTarget(enemy, self.enemies, self) then value = value - 1 end
		if self:needKongcheng(enemy) then value = value - 1 end
		if enemy:getMark("@kuiwei") > 0 then value = value - 2 end
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

sgs.ai_use_value.SupplyShortage = 7
sgs.ai_keep_value.SupplyShortage = 3.48
sgs.ai_use_priority.SupplyShortage = 0.5
sgs.ai_card_intention.SupplyShortage = 120

sgs.dynamic_value.control_usecard.SupplyShortage = true

function SmartAI:getChainedFriends(player)
	player = player or self.player
	local chainedFriends = {}
	for _, friend in ipairs(self:getFriends(player)) do
		if friend:isChained() then
			table.insert(chainedFriends, friend)
		end
	end
	return chainedFriends
end

function SmartAI:getChainedEnemies(player)
	player = player or self.player
	local chainedEnemies = {}
	for _, enemy in ipairs(self:getEnemies(player)) do
		if enemy:isChained() then
			table.insert(chainedEnemies,enemy)
		end
	end
	return chainedEnemies
end

function SmartAI:isGoodChainPartner(player)
	player = player or self.player
	if hasBuquEffect(player) or (self.player:hasSkill("niepan") and self.player:getMark("@nirvana") > 0) or self:needToLoseHp(player)
		or self:getDamagedEffects(player) or (player:hasSkill("fuli") and player:getMark("@laoji") > 0) then
		return true
	end
	return false
end

function SmartAI:isGoodChainTarget(who, source, nature, damagecount, card)
	source = source or self.player

	if source:hasSkill("jueqing") then return not self:isFriend(who) end
	if not who:isChained() then return not self:isFriend(who) end
	nature = nature or sgs.DamageStruct_Fire
	damagecount = damagecount or 1
	if card and card:isKindOf("Slash") then
		nature = card:isKindOf("FireSlash") and sgs.DamageStruct_Fire
					or card:isKindOf("ThunderSlash") and sgs.DamageStruct_Thunder
					or card:isKindOf("IceSlash") and sgs.DamageStruct_Ice
					or sgs.DamageStruct_Normal
		damagecount = self:hasHeavySlashDamage(source, card, who, true)
	elseif nature == sgs.DamageStruct_Fire then
		if who:hasArmorEffect("vine") then damagecount = damagecount + 1 end
		if who:getMark("@gale") > 0 and self.room:findPlayerBySkillName("kuangfeng") then damagecount = damagecount + 1 end
	end
	
	--曹節守璽不要元素殺
	if card and card:isKindOf("Slash") and who:hasSkill("shouxi") then
		local shouxi_mark_count = 0
		for _, mark in sgs.list(who:getMarkNames()) do
			if string.find(mark, "shouxi") and who:getMark(mark) > 0 then
				shouxi_mark_count = shouxi_mark_count + 1
			end
		end
		return shouxi_mark_count > 13
	end

	if hasWulingEffect("@fire") then nature = sgs.DamageStruct_Fire
	elseif not (card and card:isKindOf("Slash")) and hasWulingEffect("@thunder") and nature == sgs.DamageStruct_Thunder then damagecount = damagecount + 1
	elseif not (card and card:isKindOf("Slash")) and hasWulingEffect("@wind") and nature == sgs.DamageStruct_Fire then damagecount = damagecount + 1
	end

	if not self:damageIsEffective(who, nature, source, card) then return false end
	if card and card:isKindOf("TrickCard") and not self:hasTrickEffective(card, who, self.player) then return false end

	if who:hasArmorEffect("silver_lion") then damagecount = 1 end

	local kills, killlord, the_enemy = 0
	local good, bad, F_count, E_count = 0, 0, 0, 0
	local peach_num = self.player:objectName() == source:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", source, self.player)

	local function getChainedPlayerValue(target, dmg)
		local newvalue = 0
		if self:isGoodChainPartner(target) then newvalue = newvalue + 1 end
		if self:isWeak(target) then newvalue = newvalue - 1 end
		if dmg then
			if nature == sgs.DamageStruct_Fire then
				if target:hasArmorEffect("vine") then dmg = dmg + 1 end
				if target:getMark("@gale") > 0 then dmg = dmg + 1 end
				if hasWulingEffect("wind") then dmg = dmg + 1 end
			elseif nature == sgs.DamageStruct_Thunder then
				if hasWulingEffect("@thunder") then dmg = dmg + 1 end
			end
		end
		if self:cantbeHurt(target, source, damagecount) then newvalue = newvalue - 100 end
		if damagecount + (dmg or 0) >= target:getHp() then
			newvalue = newvalue - 2
			if target:isLord() and not self:isEnemy(target) then killlord = true end
			if self:isEnemy(target) then kills = kills + 1 end
		else
			if self:isEnemy(target) and source:getHandcardNum() < 2 and target:hasSkills("ganglie|neoganglie|xuelin") and source:getHp() == 1
				and self:damageIsEffective(source, nil, target) and peach_num < 1 then newvalue = newvalue - 100 end
			if target:hasSkill("vsganglie") then
				local can
				for _, t in ipairs(self:getFriends(source)) do
					if t:getHp() == 1 and t:getHandcardNum() < 2 and self:damageIsEffective(t, nil, target) and peach_num < 1 then
						if t:isLord() then
							newvalue = newvalue - 100
							if not self:isEnemy(t) then killlord = true end
						end
						can = true
					end
				end
				if can then newvalue = newvalue - 2 end
			end
		end

		if target:hasArmorEffect("silver_lion") then return newvalue - 1 end
		return newvalue - damagecount - (dmg or 0)
	end


	local value = getChainedPlayerValue(who)
	if self:isFriend(who) then
		good = value
		F_count = F_count + 1
	elseif self:isEnemy(who) then
		bad = value
		E_count = E_count + 1
	end

	if nature == sgs.DamageStruct_Normal then return good >= bad end

	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if player:objectName() ~= who:objectName() and player:isChained() and self:damageIsEffective(player, nature, source, card)
			and not (card and card:isKindOf("FireAttack") and not self:hasTrickEffective(card, who, self.player)) then
			local getvalue = getChainedPlayerValue(player, 0)
			if kills == #self.enemies and not killlord and sgs.getDefenseSlash(player, self) < 2 then
				if card then self.room:setCardFlag(card, "AIGlobal_KillOff") end
				return true
			end
			if self:isFriend(player) then
				good = good + getvalue
				F_count = F_count + 1
			elseif self:isEnemy(player) then
				bad = bad + getvalue
				E_count = E_count + 1
				the_enemy = player
			end
		end
	end

	if killlord and self.role == "rebel" and not sgs.GetConfig("EnableHegemony", false) then return true end

	if card and F_count == 1 and E_count == 1 and the_enemy and the_enemy:isKongcheng() and the_enemy:getHp() == 1 then
		for _, c in ipairs(self:getCards("Slash")) do
			if not c:isKindOf("NatureSlash") and not self:slashProhibit(c, the_enemy, source) then return false end
		end
	end

	if F_count > 0 and E_count <= 0 then return false end

	return good >= bad
end

function SmartAI:ironchain_fireattack_sort(players)
	if #players == 0 then return end
	local function get_cmp_value(target)
		local value = 0
		if not target:isKongcheng() then value = value + 1 end
		if target:hasArmorEffect("vine") then value = value + 1 end
		if target:getMark("@gale") > 0 then value = value + 1 end
		if target:hasSkill("ranshang") then value = value + 1 end
		if target:hasSkills(sgs.masochism_skill) and target:getHp() > 1 then value = value - 2 end
		return value
	end
	sort_func = function(a, b)
		local c1 = get_cmp_value(a)
		local c2 = get_cmp_value(b)
		if c1 == c2 then
			return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
		else
			return c1 > c2
		end
	end
	table.sort(players, sort_func)
end

function SmartAI:needChained(player)	--需要被横置
	if player:hasSkill("xuxiang") and not player:getJudgingArea():isEmpty() then	--有虚像、中兵乐、没有闪电
		local tricks = player:getJudgingArea()
		local tricks_name = {}
		for _, trick in sgs.qlist(tricks) do
			table.insert(tricks_name, trick:getClassName())
		end
		if not table.contains(tricks_name, "Lightning") and (table.contains(tricks_name, "Indulgence") or table.contains(tricks_name, "SupplyShortage")) then
			return true
		end
	end
	if player:hasSkill("xiexing") and #self:getFriends(player) < #self:getEnemies(player) then	--团队能至少亏1牌就上链子避免刷五谷
		return true
	end
	return false
end

function SmartAI:needNotChained(player)		--需要不被横置
	if player:hasSkills("lianxin|xiazhi") then
		return true
	end
	if player:hasSkill("xiexing") and #self:getFriends(player) > #self:getEnemies(player) then	--团队能至少赚1牌就解链子刷五谷
		return true
	end
	return false
end

function SmartAI:useCardIronChain(card, use)
	local needTarget = (card:getSkillName() == "guhuo" or card:getSkillName() == "nosguhuo" or card:getSkillName() == "qice")
	if self.player:hasSkills("tianqiao") and card:getId() == self.room:getDrawPile():first() then needTarget = true end	--不允许AI用天巧重铸
	if not (self.player:hasSkills("noswuyan") and needTarget) then use.card = card end	--直接重铸
	if self.player:hasSkills("yueying") and self.player:getMark("yueying_used") == 0 and not needTarget then use.card = card end	--月盈，直接重铸
	if self.player:getMark("&shenban") > 0 and needTarget then use.card = card end	--神伴效果在，直接重铸
	if not needTarget then
		if self.player:hasSkill("noswuyan") then return end
		if self.player:isLocked(card) then return end
		if #self.enemies == 1 and #(self:getChainedFriends()) <= 1 then return end
		if self:needBear() then return end
		--祖茂的引兵：如果手里只有一张铁索，这时最大效率化还是将其保留为好。
		if self.player:hasSkill("yinbing") and self.player:getPile("hat"):length() == 0 and self.player:getHandcardNum() - self:getCardsNum("BasicCard") == 1 and not self:isWeak() then return end
		if self:getOverflow() <= 0 and hasManjuanEffect(self.player) then return end
		if self.player:hasSkill("wumou") and self.player:getMark("@wrath") < 7 then return end
	end
	local friendtargets, friendtargets2 = {}, {}
	local otherfriends = {}
	local enemytargets = {}
	local yangxiu = self.room:findPlayerBySkillName("danlao")
	local liuxie = self.room:findPlayerBySkillName("huangen")
	self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		if use.current_targets and table.contains(use.current_targets, friend:objectName()) then continue end
		if friend:isChained() and not self:isGoodChainPartner(friend) and self:hasTrickEffective(card, friend) and not friend:hasSkill("danlao") 
		--不要對神劉備隊友使用
		and not friend:hasSkill("jieying")
		--不要對司馬徽隊友使用
		and not (friend:hasSkills("chenghao+yinshi") and friend:getMark("@dragon") + friend:getMark("@phoenix") == 0 and not friend:getArmor())
		--不要在有龙息效果时对队友用
		and not (self.player:hasSkill("longxi") and self.player:getMark("longxi_used") == 0)
		then
			if friend:containsTrick("lightning") then
				table.insert(friendtargets, friend)
			else
				table.insert(friendtargets2, friend)
			end
		else
			table.insert(otherfriends, friend)
		end
		--對司馬徽隊友使用
		if (not use.current_targets or not table.contains(use.current_targets, friend:objectName()))
		and not friend:isChained() and not self.room:isProhibited(self.player, friend, card)
		and (friend:hasSkills("chenghao+yinshi") and friend:getMark("@dragon") + friend:getMark("@phoenix") == 0 and not friend:getArmor())
		and self:hasTrickEffective(card, friend)
		and not self:getDamagedEffects(friend)
		and not table.contains(friendtargets2, friend)
		then
			table.insert(friendtargets2, friend)
		end
		--调整需要或不需要被横置的队友
		if (friend:isChained() and self:needNotChained(friend)) or (not friend:isChained() and self:needChained(friend)) then
			if not table.contains(friendtargets, friend) and not table.contains(friendtargets2, friend) then
				table.insert(friendtargets2, friend)
			end
		end
	end
	table.insertTable(friendtargets, friendtargets2)
	if not (liuxie and self:isEnemy(liuxie)) then
		--self:sort(self.enemies, "defense")
		--用自訂整理
		self:ironchain_fireattack_sort(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName()))
				--敌人没有被连，或能对其使用龙息
				and (not enemy:isChained() or (self.player:hasSkill("longxi") and self.player:getMark("longxi_used") == 0))
				and not self.room:isProhibited(self.player, enemy, card) and not enemy:hasSkill("danlao")
				--不要對董允敵人使用
				and not enemy:hasSkills("sheyan|buen")
				--不要對陸抗敵人使用
				and not enemy:hasSkill("qianjie")
				--不要對司馬徽敵人使用
				and not enemy:hasSkills("chenghao+yinshi")
				and self:hasTrickEffective(card, enemy) and not (self:objectiveLevel(enemy) <= 3)
				and not self:getDamagedEffects(enemy) and not self:needToLoseHp(enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
				table.insert(enemytargets, enemy)
			end
		end
	end

	local chainSelf = (not use.current_targets or not table.contains(use.current_targets, self.player:objectName()))
						and (self:needToLoseHp(self.player) or self:getDamagedEffects(self.player)) and not self.player:isChained()
						and not self.player:hasSkill("jueqing")
						and (self:getCardId("FireSlash") or self:getCardId("ThunderSlash") or self:getCardId("IceSlash") or
							(self:getCardId("Slash") and (self.player:hasWeapon("fan") or self.player:hasSkill("lihuo")))
						or (self:getCardId("FireAttack") and self.player:getHandcardNum() > 2))

	local targets_num = 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
	if not self.player:hasSkill("noswuyan") then
		if #friendtargets > 1 then
			if use.to then
				for _, friend in ipairs(friendtargets) do
					use.to:append(friend)
					if use.to:length() == targets_num then return end
				end
			end
		elseif #friendtargets == 1 then
			if #enemytargets > 0 then
				if use.to then
					use.to:append(friendtargets[1])
					for _, enemy in ipairs(enemytargets) do
						use.to:append(enemy)
						if use.to:length() == targets_num then return end
					end
				end
			elseif chainSelf then
				if use.to then use.to:append(friendtargets[1]) end
				if use.to then use.to:append(self.player) end
			elseif liuxie and self:isFriend(liuxie) and liuxie:getHp() > 0 and #otherfriends > 0 then
				if use.to then
					use.to:append(friendtargets[1])
					for _, friend in ipairs(otherfriends) do
						use.to:append(friend)
						if use.to:length() == math.min(targets_num, liuxie:getHp() + 1) then return end
					end
				end
			elseif yangxiu and self:isFriend(yangxiu) then
				if use.to then use.to:append(friendtargets[1]) end
				if use.to then use.to:append(yangxiu) end
			elseif use.current_targets then
				if use.to then use.to:append(friendtargets[1]) end
			end
		elseif #enemytargets > 1 then
			if use.to then
				for _, enemy in ipairs(enemytargets) do
					use.to:append(enemy)
					if use.to:length() == targets_num then return end
				end
			end
		elseif #enemytargets == 1 then
			if chainSelf then
				if use.to then use.to:append(enemytargets[1]) end
				if use.to then use.to:append(self.player) end
			elseif liuxie and self:isFriend(liuxie) and liuxie:getHp() > 0 and #otherfriends > 0 then
				if use.to then
					use.to:append(enemytargets[1])
					for _, friend in ipairs(otherfriends) do
						use.to:append(friend)
						if use.to:length() == math.min(targets_num, liuxie:getHp() + 1) then return end
					end
				end
			elseif yangxiu and self:isFriend(yangxiu) then
				if use.to then use.to:append(enemytargets[1]) end
				if use.to then use.to:append(yangxiu) end
			elseif use.current_targets then
				if use.to then use.to:append(enemytargets[1]) end
			end
		elseif #friendtargets == 0 and #enemytargets == 0 then
			if use.to and liuxie and self:isFriend(liuxie) and liuxie:getHp() > 0
				and (#otherfriends > 1 or (use.current_targets and #otherfriends > 0)) then
				local current_target_length = use.current_targets and #use.current_targets or 0
				for _, friend in ipairs(otherfriends) do
					if use.to:length() + current_target_length == math.min(targets_num, liuxie:getHp()) then return end
					use.to:append(friend)
				end
			elseif use.current_targets then
				if yangxiu and not table.contains(use.current_targets, yangxiu:objectName()) and self:isFriend(yangxiu) then
					if use.to then use.to:append(yangxiu) end
				elseif liuxie and not table.contains(use.current_targets, liuxie:objectName()) and self:isFriend(liuxie) and liuxie:getHp() > 0 then
					if use.to then use.to:append(liuxie) end
				end
			end
		end
	end
	if use.to then assert(use.to:length() < targets_num + 1) end
	if needTarget and use.to and use.to:isEmpty() then use.card = nil end
end

sgs.ai_card_intention.IronChain = function(self, card, from, tos)
	local liuxie = self.room:findPlayerBySkillName("huangen")
	for _, to in ipairs(tos) do
		if not to:isChained() then
			local enemy = true
			if to:hasSkill("danlao") and #tos > 1 then enemy = false end
			if liuxie and liuxie:getHp() >= 1 and #tos > 1 and self:isFriend(to, liuxie) then enemy = false end
			if to:hasSkills("chenghao+yinshi") then enemy = false end
			sgs.updateIntention(from, to, enemy and 60 or -30)
		else
			sgs.updateIntention(from, to, -60)
		end
	end
end

sgs.ai_use_value.IronChain = 5.4
sgs.ai_keep_value.IronChain = 3.34
sgs.ai_use_priority.IronChain = 9.1

sgs.ai_skill_cardask["@fire-attack"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local convert = { [".S"] = "spade", [".D"] = "diamond", [".H"] = "heart", [".C"] = "club"}
	local card
	local first_card

	self:sortByUseValue(cards, true)
	local lord = self.room:getLord()
	if sgs.GetConfig("EnableHegemony", false) then lord = nil end
	
	for _, acard in ipairs(cards) do
		if acard:getSuitString() == convert[pattern] then
			
			--增加火攻是不是隊友判斷
			if self:isFriend(target) then
				local fire_attack_self_check = false
				local fire_attack = sgs.Sanguosha:cloneCard("fire_attack")
				
				if target:objectName() ~= self.player:objectName() then
					return "."
				
				--火攻自己判斷
				elseif target:objectName() == self.player:objectName() then
					if self.player:isChained() and self:isGoodChainTarget(self.player, self.player, sgs.DamageStruct_Fire, nil, fire_attack)
					and self.player:getHandcardNum() > 1 and not self.player:hasSkill("jueqing") and not self.player:hasSkill("mingshi")
					and not self.room:isProhibited(self.player, self.player, fire_attack)
					and self:damageIsEffective(self.player, sgs.DamageStruct_Fire, self.player, fire_attack) and not self:cantbeHurt(self.player)
					and self:hasTrickEffective(fire_attack, self.player) then
						fire_attack_self_check = true
					end
					fire_attack:deleteLater()
					if not fire_attack_self_check then return "." end
				end
				fire_attack:deleteLater()
			end
			
			if not isCard("Peach", acard, self.player) then
				card = acard
				break
			else
				local needKeepPeach = true
				if (self:isWeak(target) and not self:isWeak()) or target:getHp() == 1
						or self:isGoodChainTarget(target) or target:hasArmorEffect("vine") or target:getMark("@gale") > 0 then
					needKeepPeach = false
				end
				if lord and not self:isEnemy(lord) and sgs.isLordInDanger() and self:getCardsNum("Peach") == 1 and self.player:aliveCount() > 2 then
					needKeepPeach = true
				end
				if not needKeepPeach then
					card = acard
					break
				end
			end
			if card:hasFlag("chiling_select_card") then	--炽翎加伤牌
				first_card = card
			end
		end
	end
	if first_card then
		card = first_card
	end
	return card and card:getId() or "."
end

function SmartAI:useCardFireAttack(fire_attack, use)
	if fire_attack:getSkillName() == "diyin" then	--低吟火攻
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				use.card = fire_attack
				if (use.to) then use.to:append(enemy) end
				return
			end
		end
		for _,p in sgs.qlist(self.room:getAllPlayers()) do
			if not p:isKongcheng() then
				use.card = fire_attack
				if (use.to) then use.to:append(p) end
				return
			end
		end
	end
	if self.player:hasSkill("wuyan") and not self.player:hasSkill("jueqing") then return end
	if self.player:hasSkill("noswuyan") then return end

	local lack = {
		spade = true,
		club = true,
		heart = true,
		diamond = true,
	}

	local cards = self.player:getHandcards()
	local canDis = {}
	for _, card in sgs.qlist(cards) do
		if card:getEffectiveId() ~= fire_attack:getEffectiveId() then
			table.insert(canDis, card)
			lack[card:getSuitString()] = false
		end
	end

	if self.player:hasSkill("hongyan") then
		lack.spade = true
	end

	local suitnum = 0
	for suit,islack in pairs(lack) do
		if not islack then suitnum = suitnum + 1  end
	end


	--self:sort(self.enemies, "defense")
	--用自訂整理
	self:ironchain_fireattack_sort(self.enemies)

	local can_attack = function(enemy)
		if self.player:hasFlag("FireAttackFailed_" .. enemy:objectName()) then
			return false
		end
		if enemy:hasSkill("qianxun") then return false end
		--local damage = 1
		--if not self.player:hasSkill("jueqing") and not enemy:hasArmorEffect("silver_lion") then
		--	if enemy:hasArmorEffect("vine") then damage = damage + 1 end
		--	if enemy:getMark("@gale") > 0 then damage = damage + 1 end
		--end
		--if not self.player:hasSkill("jueqing") and enemy:hasSkill("mingshi") and self.player:getEquips():length() <= enemy:getEquips():length() then
		--	damage = damage - 1
		--end
		local damage = self:getDamageAdjustment(self.player, enemy, fire_attack, 1, sgs.DamageStruct_Fire)
		return self:objectiveLevel(enemy) > 3 and damage > 0 and not enemy:isKongcheng() and not self.room:isProhibited(self.player, enemy, fire_attack)
				and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player, fire_attack) and not self:cantbeHurt(enemy, self.player, damage)
				and self:hasTrickEffective(fire_attack, enemy)
				and sgs.isGoodTarget(enemy, self.enemies, self)
				and (
					self.player:hasSkill("jueqing")
					or (
						not (enemy:hasSkill("jianxiong") and not self:isWeak(enemy))
						and not (enemy:hasSkill("guixin") and enemy:getHp() > 1 and sgs.turncount <= 1)
						and not (self:getDamagedEffects(enemy, self.player))
						and not (enemy:isChained() and not self:isGoodChainTarget(enemy, self.player, sgs.DamageStruct_Fire, nil, fire_attack))
						)
					)
	end

	local enemies, targets = {}, {}
	for _, enemy in ipairs(self.enemies) do
		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName())) and can_attack(enemy) then
			table.insert(enemies, enemy)
		end
	end

	local can_FireAttack_self
	for _, card in ipairs(canDis) do
		if (not isCard("Peach", card, self.player) or self:getCardsNum("Peach") >= 3)
			and (not isCard("Analeptic", card, self.player) or self:getCardsNum("Analeptic") >= 2) then
			can_FireAttack_self = true
		end
	end

	if (not use.current_targets or not table.contains(use.current_targets, self.player:objectName()))
		and self.role ~= "renegade" and can_FireAttack_self and self.player:isChained() and self:isGoodChainTarget(self.player, self.player, sgs.DamageStruct_Fire, nil, fire_attack)
		and self.player:getHandcardNum() > 1 and not self.player:hasSkill("jueqing") and not self.player:hasSkill("mingshi")
		and not self.room:isProhibited(self.player, self.player, fire_attack)
		and self:damageIsEffective(self.player, sgs.DamageStruct_Fire, self.player, fire_attack) and not self:cantbeHurt(self.player)
		and self:hasTrickEffective(fire_attack, self.player) then

		if self.player:hasSkill("niepan") and self.player:getMark("@nirvana") > 0 then
			table.insert(targets, self.player)
		elseif hasBuquEffect(self.player)then
			table.insert(targets, self.player)
		else
			local leastHP = 1
			if self.player:hasArmorEffect("vine") then leastHP = leastHP + 1 end
			if self.player:getMark("@gale") > 0 then leastHP =leastHP + 1 end
			local jxd = self.room:findPlayerBySkillName("wuling")
			if jxd and jxd:getMark("@wind") > 0 then leastHP = leastHP + 1 end
			if self.player:getHp() > leastHP then
				table.insert(targets, self.player)
			elseif self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > self.player:getHp() - leastHP then
				table.insert(targets, self.player)
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName())) and enemy:getHandcardNum() == 1 then
			local handcards = sgs.QList2Table(enemy:getHandcards())
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
			if handcards[1]:hasFlag("visible") or handcards[1]:hasFlag(flag) then
				local suitstring = handcards[1]:getSuitString()
				if not lack[suitstring] and not table.contains(targets, enemy) then
					table.insert(targets, enemy)
				end
			end
		end
	end

	if ((suitnum == 2 and lack.diamond == false) or suitnum <= 1)
		and self:getOverflow() <= (self.player:hasSkills("jizhi|nosjizhi") and -2 or 0)
		and #targets == 0 then return end

	for _, enemy in ipairs(enemies) do
		local damage = 1
		if not enemy:hasArmorEffect("silver_lion") then
			if enemy:hasArmorEffect("vine") then damage = damage + 1 end
			if enemy:getMark("@gale") > 0 then damage = damage + 1 end
		end
		if not self.player:hasSkill("jueqing") and enemy:hasSkill("mingshi") and self.player:getEquips():length() <= enemy:getEquips():length() then
			damage = damage - 1
		end
		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName()))
			and not self.player:hasSkill("jueqing") and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player, fire_attack) and damage > 1 then
			if not table.contains(targets, enemy) then table.insert(targets, enemy) end
		end
	end
	for _, enemy in ipairs(enemies) do
		if (not use.current_targets or not table.contains(use.current_targets, enemy:objectName())) and not table.contains(targets, enemy) then table.insert(targets, enemy) end
	end
	
	for _, enemy in ipairs(enemies) do
		if enemy:getHandcardNum() == 1 then
			local handcards = sgs.QList2Table(enemy:getHandcards())
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
			if handcards[1]:hasFlag("visible") or handcards[1]:hasFlag(flag) then
				local suitstring = handcards[1]:getSuitString()
				if lack[suitstring] and table.contains(targets, enemy) then
					table.removeOne(targets, enemy)
				end
			end
		end
	end

	if #targets > 0 then
		local godsalvation = self:getCard("GodSalvation")
		if godsalvation and godsalvation:getId() ~= fire_attack:getId() and self:willUseGodSalvation(godsalvation) then
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

		local targets_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, fire_attack)
		if use.isDummy and use.extra_target then targets_num = targets_num + use.extra_target end
		local lx = self.room:findPlayerBySkillName("huangen")
		use.card = fire_attack
		for i = 1, #targets, 1 do
			if use.to and not (use.to:length() > 0 and targets[i]:hasSkill("danlao"))
				and not (use.to:length() > 0 and lx and self:isFriend(lx, targets[i]) and self:isEnemy(lx) and lx:getHp() > targets_num / 2) then
				use.to:append(targets[i])
				if use.to:length() == targets_num then return end
			end
		end
	end
end

sgs.ai_cardshow.fire_attack = function(self, requestor)
	local cards = sgs.QList2Table(self.player:getHandcards())
	if requestor:objectName() == self.player:objectName() then
		self:sortByUseValue(cards, true)
		return cards[1]
	end

	local priority = { heart = 4, spade = 3, club = 2, diamond = 1 }
	if requestor:hasSkill("hongyan") then priority = { spade = 10, club = 2, diamond = 1, heart = 0 } end
	local index = -1
	local result
	for _, card in ipairs(cards) do
		if priority[card:getSuitString()] > index then
			result = card
			index = priority[card:getSuitString()]
		end
	end

	return result
end

sgs.ai_use_value.FireAttack = 4.8
sgs.ai_keep_value.FireAttack = 3.3
sgs.ai_use_priority.FireAttack = sgs.ai_use_priority.Dismantlement + 0.1

sgs.dynamic_value.damage_card.FireAttack = true

--sgs.ai_card_intention.FireAttack = 80
sgs.ai_card_intention.FireAttack = function(self, card, from, tos)
	if string.find(card:getSkillName(), "m_lianjicard") then return end
	if string.find(card:getSkillName(), "diyin") then return end	--低吟火攻不计入仇恨
	sgs.updateIntentions(from, tos, 80)
end

sgs.dynamic_value.damage_card.FireAttack = true

function SmartAI:useCardGodNihilo(card, use)
	
	if self.room:getMode() == "06_ol" and self:DoNotUseofGodNihilo() then return end
	
	if self.player:getKingdom() ~= "god" and self.player:getHandcardNum() > math.min(5, self.player:getMaxHp()) then return end
	
	local xiahou = self.room:findPlayerBySkillName("yanyu")
	if xiahou and self:isEnemy(xiahou) and xiahou:getMark("YanyuDiscard2") > 0 then return end

	use.card = card
	if not use.isDummy then
		self:speak("lucky")
	end
end

sgs.ai_card_intention.GodNihilo = -80

sgs.ai_keep_value.GodNihilo = 5
sgs.ai_use_value.GodNihilo = 10
sgs.ai_use_priority.GodNihilo = 1

sgs.dynamic_value.benefit.GodNihilo = true

--SmartAI.useCardGodFlower = SmartAI.useCardSnatchOrDismantlement
function SmartAI:useCardGodFlower(card, use)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	self:sort(self.friends, "handcard")
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() < 4 and enemy:getHandcardNum() > 0 and not self.room:isProhibited(self.player, enemy, card) then
			table.insert(targets, enemy)
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		for _, enemy in ipairs(self.enemies) do
			if friend:getHandcardNum() >= 4 and friend:canSlash(enemy, nil) and not self.room:isProhibited(self.player, friend, card)  then
				table.insert(targets, friend)
			end
		end
	end
	if #targets == 0 then return end
	use.card = card
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_value.GodFlower = 9
sgs.ai_use_priority.GodFlower = 4.3
sgs.ai_keep_value.GodFlower = 3.46
sgs.dynamic_value.control_card.GodFlower = true
