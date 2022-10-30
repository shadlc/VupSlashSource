
--------------------------------------------------
--判断是否能被技能指定为目标
--注意与VupV0.lua同步
--------------------------------------------------

function SkillCanTarget(to, player, skill_name)	--判断是否能被技能指定为目标
	if player:objectName() ~= to:objectName() and to:hasSkill("muying") then	--幕影
		return false
	end
	if skill_name == "lingan" and to:getMark("lingan_banned") > 0 then	--灵黯
		return false
	end
	if to:getMark("&suoke") > 0 then	--缩壳
		return false
	end
	return true
end

--------------------------------------------------
--函数部分
--------------------------------------------------

--三目运算符--

Ternary = function(A, B, C)
	if A then
		return B
	else
		return C
	end
end

--将牌的类别转化为字符串--

getTypeString = function(card)
	if card:isKindOf("BasicCard") then
		return "basic"
	elseif card:isKindOf("TrickCard") then
		return "trick"
	elseif card:isKindOf("EquipCard") then
		return "equip"
	end
end

getTypeKindString = function(card)
	if card:isKindOf("BasicCard") then
		return "BasicCard"
	elseif card:isKindOf("TrickCard") then
		return "TrickCard"
	elseif card:isKindOf("EquipCard") then
		return "EquipCard"
	end
end

--将牌的颜色转化为字符串--

getColorString = function(card)
	if card:isRed() then
		return "red"
	elseif card:isBlack() then
		return "black"
	end
	return "no_suit"
end

--高效返回table内某个元素的索引值（仅限数字/字符串）--

function revtab(tab)	--将table的索引和内容反转
	local revtab = {}
	for key, value in pairs(tab) do
		revtab[value] = key
	end
	return revtab
end

function AtTable(tab, value)	--直接返回对应的索引值
	return revtab(tab)[value]
end

--将数字转化为点数字符串--

function getNumberChar(X)
	if X == 1 then
		return "A"
	elseif X == 11 then
		return "J"
	elseif X == 12 then
		return "Q"
	elseif X == 13 then
		return "K"
	else
		return tostring(X)
	end
end


--根据flag找角色--
function findPlayerByFlag(room, flag_name)
	for _,p in sgs.qlist(room:getAllPlayers(true)) do
		if p:hasFlag(flag_name) then
			return p
		end
	end
	return nil
end

--根据objectName找角色--
function findPlayerByObjName(room, obj_name)
	for _,p in sgs.qlist(room:getAllPlayers(true)) do
		if p:objectName() == obj_name then
			return p
		end
	end
	return nil
end

--缔盟的弃牌策略--
local dimeng_discard = function(self, discard_num, mycards, up_limit, aux_func)
	local cards = mycards
	up_limit = up_limit or 999
	local to_discard = {}

	local new_aux_func = function(card)
		if self:isTemporaryCard(self.player, card:getEffectiveId()) then return -1 end	--临时牌优先扔，仅次于扔狮子
		local place = self.room:getCardPlace(card:getEffectiveId())
		if place == sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") and self.player:isWounded() and not self:needToLoseHp(self.player, self.player, false, false, true) then return -2
			elseif card:isKindOf("OffensiveHorse") then return 1
			elseif card:isKindOf("Weapon") then return 2
			elseif card:isKindOf("DefensiveHorse") or card:isKindOf("Treasure") then return 3
			elseif card:isKindOf("Armor") then return 4
			end
		elseif self:getUseValue(card) >= 6 then return 3 --使用价值高的牌，如顺手牵羊(9),下调至桃
		elseif self:hasSkills(sgs.lose_equip_skill) then return 5
		else return 0
		end
		return 0
	end
	
	aux_func = aux_func or new_aux_func

	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then
			return aux_func(a) < aux_func(b)
		end
		return self:getKeepValue(a) < self:getKeepValue(b)
	end

	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if not self.player:isJilei(card) and aux_func(card) < up_limit then table.insert(to_discard, card:getId()) end
		if #to_discard >= discard_num then break end
	end
	if #to_discard ~= discard_num then return {} end
	return to_discard
end

--------------------------------------------------

--------------------------------------------------
--冰霜伤害-寒冰剑效果
--------------------------------------------------

sgs.ai_skill_invoke.ice_type_damage = function(self, data)
	local data = self.player:getTag("ice_type_damage_data_AI")
	local damage = data:toDamage()
	local target = damage.to
	local result = false
	self.ignore_ice = true
	if self:shouldNotDamage(self.player) then	--不应造成伤害则直接防止
		result = true goto ice_type_damage_return
	end

	for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do	--需要造成伤害则直接取消
		local callback = sgs.ai_need_damage[askill:objectName()]
		if type(callback) == "function" and callback(self, self.player, target) then
			goto ice_type_damage_return
		end
	end
	
	if self:isFriend(target) then
		if self:getDamagedEffects(target, self.player, true) or self:needToLoseHp(target, self.player, true) then goto ice_type_damage_return
		elseif target:isChained() and self:isGoodChainTarget(target, self.player, nil, nil, damage.card) then goto ice_type_damage_return
		elseif self:isWeak(target) or damage.damage > 1 then result = true goto ice_type_damage_return
		elseif target:getLostHp() < 1 then goto ice_type_damage_return end
		result = true goto ice_type_damage_return
	else
		if self:isWeak(target) then goto ice_type_damage_return end
		if damage.damage > 1 or self:hasHeavySlashDamage(self.player, damage.card, target) then goto ice_type_damage_return end
		if target:hasSkill("lirang") and #self:getFriendsNoself(target) > 0 then goto ice_type_damage_return end
		if target:getArmor() and self:evaluateArmor(target:getArmor(), target) > 3 and not (target:hasArmorEffect("silver_lion") and target:isWounded()) then result = true goto ice_type_damage_return end
		local num = target:getHandcardNum()
		if self.player:hasSkill("tieji") or self:canLiegong(target, self.player) then goto ice_type_damage_return end
		if target:hasSkills("tuntian+zaoxian") and target:getPhase() == sgs.Player_NotActive then goto ice_type_damage_return end
		if self:hasSkills(sgs.need_kongcheng, target) then goto ice_type_damage_return end
		if target:getCards("he"):length()<4 and target:getCards("he"):length()>1 then result = true goto ice_type_damage_return end
		goto ice_type_damage_return
	end
::ice_type_damage_return::
	self.ignore_ice = false
	return result
end

--------------------------------------------------
--斗地主农民离场摸牌回血询问
--------------------------------------------------

sgs.ai_skill_choice.doudizhu = function(self, choices)
	if self.player:isWounded() and (self:isWeak() or self.player:hasSkills(sgs.masochism_skill) or (self.player:getPhase() <= sgs.Player_Discard and self:getOverflow() > 0)) then
		return "recover"
	end
	if self:canDraw() then
		return "draw"
	end
	if not self:needToLoseHp(self.player, self.player, false, false, true) then	--needToLoseHp的第五个参数为真则考虑回血后情况
		return "recover"
	end
	return "cancel"
end

--------------------------------------------------
--残机（两轮车）
--------------------------------------------------

local lianglunche_skill_skill={}
lianglunche_skill_skill.name="lianglunche_skill"
table.insert(sgs.ai_skills,lianglunche_skill_skill)
lianglunche_skill_skill.getTurnUseCard=function(self)
	if self.player:getMark("lianglunche_notready") > 0 or self.player:getMark("last_used_id_in_play_phase") == 0 or self.player:getPhase() ~= sgs.Player_Play or self.player:getMark("Equips_Nullified_to_Yourself") > 0 then return end
	local name = sgs.Sanguosha:getCard(self.player:getMark("last_used_id_in_play_phase")-1):objectName()
	if not name or name == "" then return end
	
	local cards = self.player:getCards("e")
	cards = sgs.QList2Table(cards)

	local card

	for _,acard in ipairs(cards) do
		if acard:isKindOf("Lianglunche") then
			card = acard
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = (""..name..":lianglunche[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end

--------------------------------------------------
--雌雄双股剑MK2
--------------------------------------------------

sgs.ai_skill_invoke.doubleswordmk2 = sgs.ai_skill_invoke.double_sword
sgs.weapon_range.Doubleswordmk2 = 2
sgs.ai_use_priority.Doubleswordmk2 = sgs.ai_use_priority.DoubleSword

function sgs.ai_slash_weaponfilter.doubleswordmk2(self, to, player)
	return player:distanceTo(to) <= math.max(sgs.weapon_range.DoubleSword, player:getAttackRange()) and player:getGender() ~= to:getGender()
end

function sgs.ai_weapon_value.doubleswordmk2(self, enemy, player)
	if enemy and (enemy:isMale() ~= player:isMale() or enemy:isNeuter()) and not enemy:isSexless() then return 4 end
end

--------------------------------------------------
--雪年糕棍
--------------------------------------------------

sgs.weapon_range.Xueniangaogun = 2
sgs.ai_use_priority.Xueniangaogun = 2.647

--------------------------------------------------
--藏宝图
--------------------------------------------------

sgs.ai_skill_invoke.cangbaotu = function(self, data)
	return self:canDraw() and (not self:willSkipPlayPhase() or sgs.Sanguosha:getCard(self.player:getPile("cangbaotu_pile"):first()):isKindOf("Nullification") or self:getOverflow() < -2)
end

--------------------------------------------------
--灵剑
--------------------------------------------------

sgs.weapon_range.Sssulong = 2
sgs.weapon_range.Ssfusang = 2
sgs.weapon_range.Ssxuehe = 2
sgs.weapon_range.Ssfengchan = 2
sgs.weapon_range.Ssxianghu = 2
sgs.weapon_range.Ssyuegui = 2

--------------------------------------------------
--灵剑扶桑
--------------------------------------------------

sgs.ai_skill_cardask["@ssfusang_show"] = function(self, data, pattern, target)
	local discard_list = {}
	for _,cd in sgs.qlist(self.player:getHandcards()) do
		if not cd:isOvert() then
			table.insert(discard_list, cd)
		end
	end
	self:sortByKeepValue(discard_list)
	if #discard_list > 1 then	--若之后要弃牌（非明置牌>1）则优先保护关键牌
		discard_list = sgs.reverse(discard_list)
	end
	return "$"..discard_list[1]:getEffectiveId()
end

sgs.ai_skill_cardask["@ssfusang_dis"] = function(self, data, pattern, target)
	local discard_list = {}
	for _,cd in sgs.qlist(self.player:getHandcards()) do
		if not cd:isOvert() then
			table.insert(discard_list, cd)
		end
	end
	self:sortByKeepValue(discard_list)
	return "$"..discard_list[1]:getEffectiveId()
end

--------------------------------------------------
--风卷残云
--------------------------------------------------

sgs.weapon_range.Fengjuancanyun = 3
sgs.ai_use_priority.Fengjuancanyun = 2.64

--------------------------------------------------
--应援
--------------------------------------------------

local HLyingyuan_skill={}
HLyingyuan_skill.name="HLyingyuan"
table.insert(sgs.ai_skills,HLyingyuan_skill)
HLyingyuan_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#HLyingyuanCard") and not self.player:isKongcheng() and not self:needBear() then
		local can_use = true
		for _, enemy in ipairs(self.enemies) do		--如果敌方有这些技能，就不用应援了
			if enemy:hasSkills("suoqiu") then
				can_use = false
				break
			end
		end
		if can_use then
			return sgs.Card_Parse("#HLyingyuanCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#HLyingyuanCard"] = function(card, use, self)
	self:sort(self.friends_noself, "defense")
	local hasfriend = false
	for _, friend in ipairs(self.friends_noself) do
		if friend:isAlive() and not hasManjuanEffect(friend) and not (self:needKongcheng(friend) and friend:isKongcheng()) and (self:getOverflow(self.player, true) > 0 or ((self:isWeak(friend) or (friend:getHp() + friend:getHandcardNum() <= self.player:getHp() + self.player:getHandcardNum()) and self.player:getHandcardNum() >= 2) and not self:isWeak())) then
			if friend:hasSkills("liucai") then continue end	--不应应援的技能
			if self.player:getRole() == friend:getRole() or (self.player:getRole() == "lord" and friend:getRole() == "loyalist") or (self.player:getRole() == "loyalist" and friend:getRole() == "lord") then
				hasfriend = true
				target = friend
				break
			end
		end
	end
	
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local compare_func = function(a, b)		--队友需要的牌排最前面，其次是保留价值超低的（不应该留在手里的牌），最后按照保留价值从高到低排序
		local v1 = self:getKeepValue(a)
		local v2 = self:getKeepValue(b)
		if v1 < -5 then
			v1 = 9
		end
		if v2 < -5 then
			v2 = 9
		end
		if self:needCard(target, a) then
			v1 = v1 + 10
		end
		if self:needCard(target, b) then
			v2 = v2 + 10
		end
		return v1 > v2
	end
	table.sort(cards, compare_func)
	
	
	if not hasfriend then return end
	local overflow = self:getOverflow()	--先计算自身溢出数，避免下面的长篇判断重复调用
	local overflow_target = self:getOverflow(target)	--队友溢出数
	for _, scard in ipairs(cards) do
		if scard and not (scard:isKindOf("Peach") and self.player:isWounded() and (not self:isWeak(target) or not target:isWounded()) and not self:needKongcheng())	--不应援能吃的桃
			and not ((scard:isKindOf("Indulgence") or scard:isKindOf("SupplyShortage")) and self:willUse(self.player, scard))	--不应援能用的兵乐
			and not self:isPoisonousCard(scard, target, self.player)	--不给毒牌（目标绝对不要的牌）
			and not self:needBearCard(scard, self.player, self:isWeak(self.player, true))	--不给自己需要囤的牌
			and not scard:hasFlag("&gugu")	--不应援咕牌
			and not (scard:hasFlag("&migao") and self:getKeepValue(scard) < 0)	--不应援应该弃置的蜜糕牌
			and not (overflow <= 0 and self:willSkipPlayPhase(target) and (overflow_target + 1 + self:ImitateResult_DrawNCards(target, target:getVisibleSkillList(true))) >= 0)	--自身不溢出、队友将跳过出牌阶段且给牌+摸牌后手牌溢出，不应援
			and not ((scard:isKindOf("Peach") or scard:isKindOf("Jink")) and overflow <= 0 and sgs.getDefense(self.player) <= sgs.getDefense(target))	--自身不溢出、状态差于队友时不交闪桃
			and not (overflow <= 0 and self.player:hasSkills(sgs.cardneed_skill) and not target:hasSkills(sgs.cardneed_skill)) then		--自身不溢出、自身有需要牌的技能但队友没有时不应援
			
			local card_str = "#HLyingyuanCard:"..scard:getId()..":->"..target:objectName()
			local acard = sgs.Card_Parse(card_str)
			assert(acard)
			use.card = acard
			break
		end
	end
	if use.to then
		use.to:append(target)
	end
	return
end

sgs.ai_use_priority["HLyingyuanCard"] = 1.3

--------------------------------------------------
--联动大作战-队友死亡摸一张
--------------------------------------------------

sgs.ai_skill_invoke.tietie_draw = function(self, data)
	return self:canDraw(self.player)
end

--------------------------------------------------
--CP离场的惩罚
--------------------------------------------------

function nosganglie_discard_EX(self, discard_num, min_num, optional, include_equip, damage_from, isDamage)	--进化后的最强刚烈ai（误）
	--local damage_from = self.room:findPlayerBySkillName(skillName)
	if damage_from and isDamage and (not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, damage_from) or self:getDamagedEffects(self.player, damage_from)) and optional then return {} end
	if self:needToLoseHp(self.player, damage_from) and optional then return {} end
	local to_discard = {}
	local cards
	if include_equip then
		cards = self.player:getCards("he")
	else
		cards = self.player:getHandcards()
	end
	cards = sgs.QList2Table(cards)
	local index = 0
	local all_peaches = 0
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			all_peaches = all_peaches + 1
		end
	end
	if all_peaches >= min_num and self:getOverflow() <= 0 then return {} end
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not isCard("Peach", card, self.player) and not self.player:isJilei(card) then
			table.insert(to_discard, card:getEffectiveId())
			table.remove(cards, i)
			index = index + 1
			if index == min_num then break end
		end
	end
	if #to_discard < min_num then
		if optional then
			return {}
		else
			return self:askForDiscard("", discard_num, min_num, optional, include_equip)
		end
	else
		return to_discard
	end
end

sgs.ai_skill_discard["cp_died"] = function(self, discard_num, min_num, optional, include_equip)
	return nosganglie_discard_EX(self, discard_num, min_num, optional, include_equip, nil, false)
end

--------------------------------------------------
--冰火歌会-刷技能和把技能送给塔
--------------------------------------------------

local cheer_marks = {"@Cheer_1","@Cheer_2","@Cheer_3","@Cheer_4","@Cheer_5","@Cheer_6","@Cheer_7","@Cheer_8"}

sgs.ai_skill_invoke.IFModeCheerSystem = function(self, data)
	if self.player:hasSkills("xingyao_if|longyun_if") then
		return false
	end
	if data:toString() == "choice:" then
		local count = 0
		for _, cheer_mark in ipairs(cheer_marks) do
			if self.player:getMark(cheer_mark) > 0 then
				count = count + 1
			end
		end
		if count >= 3 or self:isWeak() then
			return true
		end
	elseif data:toString() == "choice2:" then
		return math.random(1,2) == 1
	end
	return false
end





--嘲讽
sgs.ai_chaofeng.baishenyao_zhaijiahaibao = 1

--------------------------------------------------
--抽卡
--------------------------------------------------

sgs.ai_skill_invoke.chouka = function(self, data)
	return true
end

sgs.ai_skill_choice.chouka = function(self, choices)
	if self.player:getHandcardNum() <= 1 or self.player:getMark("chouka_AI") > 1 then
		return "chouka_stop"
	end
	return "chouka_repeat"
end

--------------------------------------------------
--慵懒
--------------------------------------------------

sgs.ai_view_as.yonglan = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getMark("yonglan_used") == 0 and player:getMark("yonglan_number") ~= 0 and card:getNumber() > player:getMark("yonglan_number") and card_place == sgs.Player_PlaceHand then
		return ("jink:yonglan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_cardneed.yonglan = function(to, card, self)	--需要大点至少一张
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	end
end

--------------------------------------------------
--慵懒（冰火歌会）
--------------------------------------------------

sgs.ai_view_as.yonglan_if = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getMark("yonglan_if_used") == 0 and player:getMark("yonglan_if_number") ~= 0 and card:getNumber() > player:getMark("yonglan_if_number") and card_place == sgs.Player_PlaceHand then
		return ("jink:yonglan_if[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_cardneed.yonglan_if = function(to, card, self)	--需要大点至少一张
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	end
end



--嘲讽
sgs.ai_chaofeng.hongxiaoyin_qiannianmofashi = -2

--------------------------------------------------
--永宁
--------------------------------------------------

sgs.ai_skill_playerchosen.yongning = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "handcard")
	
	local first, second, third
	
	for _, p in ipairs(targetlist) do
		if self:isEnemy(p) then
			if not first and (p:hasSkills("xianwei|diyin|yunyao|mingxian|fengjin") and p:getMark("&yongning+TrickCard") == 0) then	--优先特化针对
				first = p
			elseif not second and p:getMark("&yongning+BasicCard") == 0 then
				second = p
			elseif not third then
				third = p
			end
		end
	end
	return first or second or third
end

sgs.ai_playerchosen_intention.yongning = function(self, from, to)
	local intention = 10
	sgs.updateIntention(from, to, intention)
end

sgs.ai_skill_choice.yongning = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local to = findPlayerByFlag(self.room, "yongning_target_AI")
		if to then
			if to:hasSkills("xianwei|diyin|yunyao|mingxian|fengjin") and table.contains(items, "TrickCard") then	--特化封锦囊
				return "TrickCard"
			end
		end
		if table.contains(items, "BasicCard") then
			return "BasicCard"
		elseif table.contains(items, "TrickCard") then
			return "TrickCard"
		elseif table.contains(items, "EquipCard") then
			return "EquipCard"
		end
	end
end



--嘲讽
sgs.ai_chaofeng.hongxiaoyin_heilangniao = 1

--------------------------------------------------
--魔刺
--------------------------------------------------

sgs.ai_skill_discard.moci = function(self, discard_num, min_num, optional, include_equip)
	local toDis = {}
	local will_use = {}
	local will_use_dmg = {}		--先筛选出可以一回合用掉的伤害类牌
	local will_use_value = {}	--要用的高价值非伤害类牌（无中、好装备等，桃除外，不应该被进攻思路阻断的牌）
	local slash_count = 0
	local hcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(hcards)
	for _, hcard in ipairs(hcards) do
		if self:willUse(self.player, hcard) and not (hcard:isKindOf("Slash") and (slash_count > 0 and not self:hasCrossbowEffect())) then
			if hcard:isKindOf("Slash") then
				slash_count = slash_count + 1
			end
			
			table.insert(will_use, hcard)
			if hcard:isDamageCard() then
				table.insert(will_use_dmg, hcard)
			elseif not hcard:isKindOf("Peach") and self:getUseValue(hcard) >= 6 then
				table.insert(will_use_value, hcard)
			end
		end
	end
	if #will_use_dmg > 0 and #will_use_value < 2 and self.player:getHandcardNum() >= 4 then		--进攻思路，除外至少3张牌，剩下的进攻牌拿出去用（有至少2张很需要用的非伤害牌时不采纳）
		for _, hcard in ipairs(hcards) do
			if not table.contains(will_use_dmg, hcard) and not table.contains(toDis, hcard:getEffectiveId()) then
				table.insert(toDis, hcard:getEffectiveId())
			end
		end
		if #toDis < 3 then
			for _, hcard in ipairs(hcards) do
				if #toDis < 3 and not table.contains(toDis, hcard:getEffectiveId()) then
					table.insert(toDis, hcard:getEffectiveId())
				end
			end
		end
		return toDis
	end
	if (self.player:getHandcardNum() - #will_use) >= self:getOverflow(self.player, true) then	--存牌思路，若不能用的牌超出手牌上限就存
		for _, hcard in ipairs(hcards) do
			if not table.contains(will_use, hcard) and not table.contains(toDis, hcard:getEffectiveId()) then
				table.insert(toDis, hcard:getEffectiveId())
			end
		end
	end
	return toDis
end



--嘲讽
sgs.ai_chaofeng.qiulinzi_wangyinwunv = 2

--------------------------------------------------
--礼崩
--------------------------------------------------
--[[
sgs.ai_skill_invoke.libeng = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		return false
	end
	return true
end

sgs.ai_cardneed.libeng = function(to, card, self)
	return card:isKindOf("Slash") or card:isKindOf("GudingBlade")
end
]]
--------------------------------------------------
--礼崩（新版）
--------------------------------------------------

local libeng_skill = {}
libeng_skill.name = "libeng"
table.insert(sgs.ai_skills, libeng_skill)
libeng_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	if self.player:getMark("libeng_cannot_use") == 0 and self.player:canPindian() then return sgs.Card_Parse("#libeng:.:") end
end

sgs.ai_skill_use_func["#libeng"] = function(card,use,self)
	self:sort(self.enemies, "handcard")
	local cards = sgs.CardList()
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player, cards)
	if not max_card then return end
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if isCard("Slash", max_card, self.player) then slashcount = slashcount - 1 end
	if self:needKongcheng() and self.player:getHandcardNum() == 1 then
		for _, enemy in ipairs(self.enemies) do
			if self.player:canPindian(enemy) and not self:doNotDiscard(enemy, "h") then
				sgs.ai_use_priority["libeng"] = 1.2
				--self.libeng_card = max_card:getId()
				use.card = sgs.Card_Parse("#libeng:"..max_card:getId()..":->"..enemy:objectName())
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	
	--local zhugeliang = self.room:findPlayerBySkillName("kongcheng")

	local slash = self:getCard("Slash")
	local dummy_use = { isDummy = true }
	--self.player:setFlags("slashNoDistanceLimit")
	if slash then self:useBasicCard(slash, dummy_use) end
	--self.player:setFlags("-slashNoDistanceLimit")

	sgs.ai_use_priority["libeng"] = (slashcount >= 1 and dummy_use.card) and 7.2 or 1.2
	
	local need_slash_notactive = false	--可能需要回合外用杀
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkills("zuoye") then
			need_slash_notactive = true
			break
		end
	end
	if (slashcount >= 1 and slash and dummy_use.card and self.player:getMark("&libeng") < slashcount) or (need_slash_notactive and self.player:getMark("&libeng") == 0) then	--需要回合内用杀或需要回合外留buff
		for _, enemy in ipairs(self.enemies) do
			if not (self:needKongcheng(enemy) and enemy:getHandcardNum() == 1) and self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy, nil, true)	--第三项为真代表透视手牌
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 13
				if max_point > enemy_max_point or max_point >= 12 then
					--self.libeng_card = max_card:getId()
					use.card = sgs.Card_Parse("#libeng:"..max_card:getId()..":->"..enemy:objectName())
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
		
		if #self.enemies < 1 then return end
		--if dummy_use.to:length() > 1 then
		--	self:sort(self.friends_noself, "handcard")
		--	for index = #self.friends_noself, 1, -1 do
		--		local friend = self.friends_noself[index]
		--		if self.player:canPindian(friend) then
		--			local friend_min_card = self:getMinCard(friend)
		--			local friend_min_point = friend_min_card and friend_min_card:getNumber() or 100
		--			if max_point > friend_min_point then
		--				--self.libeng_card = max_card:getId()
		--				use.card = sgs.Card_Parse("#libeng:"..max_card:getId()..":->"..friend:objectName())
		--				if use.to then use.to:append(friend) end
		--				return
		--			end
		--		end
		--	end
		--end

		for index = #self.friends_noself, 1, -1 do
			local friend = self.friends_noself[index]
			if self.player:canPindian(friend) and self:needKongcheng(friend) then
				local zhugeliang = friend
				if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and zhugeliang:objectName() ~= self.player:objectName()
					and self.player:canPindian(zhugeliang) then
					if max_point >= 7 then
						--self.libeng_card = max_card:getId()
						use.card = sgs.Card_Parse("#libeng:"..max_card:getId()..":->"..zhugeliang:objectName())
						if use.to then use.to:append(zhugeliang) end
						return
					end
				end
			end
		end
		
		--if dummy_use.to:length() > 1 then
		--	for index = #self.friends_noself, 1, -1 do
		--		local friend = self.friends_noself[index]
		--		if self.player:canPindian(friend) then
		--			if max_point >= 7 then
		--				--self.libeng_card = max_card:getId()
		--				use.card = sgs.Card_Parse("#libeng:"..max_card:getId()..":->"..friend:objectName())
		--				if use.to then use.to:append(friend) end
		--				return
		--			end
		--		end
		--	end
		--end
	end

	if not (slashcount >= 1 and dummy_use.card) then
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		
		for index = #self.friends_noself, 1, -1 do
			local friend = self.friends_noself[index]
			if self.player:canPindian(friend) and self:needKongcheng(friend) then
				local zhugeliang = friend
				if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1
					and zhugeliang:objectName() ~= self.player:objectName() and self:getEnemyNumBySeat(self.player, zhugeliang) >= 1 and self.player:canPindian(zhugeliang) then
					if isCard("Jink", cards[1], self.player) and self:getCardsNum("Jink") == 1 then return end
					--self.libeng_card = cards[1]:getId()
					use.card = sgs.Card_Parse("#libeng:"..cards[1]:getId()..":->"..zhugeliang:objectName())
					if use.to then use.to:append(zhugeliang) end
					return
				end
			end
		end
	
		if self:getOverflow() > 0 or self:hasTemporaryCard() or self:getKeepValue(cards[1]) < 3 then
			for _, enemy in ipairs(self.enemies) do
				if not self:doNotDiscard(enemy, "h", true) and self.player:canPindian(enemy) then
					--self.libeng_card = cards[1]:getId()
					use.card = sgs.Card_Parse("#libeng:"..cards[1]:getId()..":->"..enemy:objectName())
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.libeng(minusecard, self, requestor)
	if requestor:getHandcardNum() == 1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return cards[1]
	end
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end

sgs.ai_cardneed.libeng = function(to, card, self)
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	else
		return card:isKindOf("Slash") or card:isKindOf("Analeptic") or card:isKindOf("GudingBlade")
	end
end

sgs.ai_card_intention["libeng"] = 0
sgs.dynamic_value.control_card["libeng"] = true

sgs.ai_use_value["libeng"] = 8.5

--------------------------------------------------
--超度
--------------------------------------------------

sgs.ai_skill_choice.chaodu = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local dying = findPlayerByFlag(self.room, "chaodu_target_AI")
		if table.contains(items, "chaodu_counter") and dying and dying:hasSkills(sgs.exclusive_skill) and self:isEnemy(dying) then
			return "chaodu_counter"
		elseif table.contains(items, "chaodu_recover") and self:isWeak() and self.player:isWounded() then
			return "chaodu_recover"
		elseif table.contains(items, "chaodu_draw") then
			return "chaodu_draw"
		end
	end
	return "cancel"
end




--嘲讽
sgs.ai_chaofeng.lingnainainai_fentujk = 0

--------------------------------------------------
--嗜甜
--------------------------------------------------

sgs.ai_skill_invoke.shitian = function(self, data)
	return true
end

--------------------------------------------------
--藏聪
--------------------------------------------------

sgs.ai_skill_invoke.cangcong = function(self, data)
	local objname = string.sub(data:toString(), 8, -1)	--截取choice:
	if objname == "analeptic" or objname == "peach" or objname == "amazing_grace" or objname == "ex_nihilo" or objname == "god_salvation" then
		return false
	end
	local from = findPlayerByFlag(self.room, "cangcong_usefrom_AI")
	if (objname == "iron_chain" or objname == "fudichouxin" or objname == "snatch" or objname == "dismantlement") and from and self:isFriend(from) then
		return false
	end
	if (objname == "slash" or objname == "fire_slash" or objname == "thunder_slash" or objname == "ice_slash" or objname == "archery_attack" or objname == "savage_assault" or objname == "fire_attack") and self:needToLoseHp() then
		return false
	end
	if (objname == "fire_slash" or objname == "thunder_slash" or objname == "ice_slash" or objname == "fire_attack") and from and self:isFriend(from) then
		return false
	end
	return true
end




--嘲讽
sgs.ai_chaofeng.buding_qiaoxinmiyou = 3

--------------------------------------------------
--天巧
--------------------------------------------------

tianqiao_skill = {}
tianqiao_skill.name = "tianqiao"
table.insert(sgs.ai_skills, tianqiao_skill)
tianqiao_skill.getTurnUseCard = function(self)
	if self.player:getPhase() == sgs.Player_Play and self.player:getMark("tianqiao_triggering") > 0 and self.player:getMark("tianqiao_used") == 0 then
		return sgs.Sanguosha:getCard(self.room:getDrawPile():first())
	end
end

--------------------------------------------------
--宴灵
--------------------------------------------------

sgs.ai_skill_invoke.yanling = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if self:getAllPeachNum(target, true) == 0 or target:getMark("@yanling") == 0 then	--宴灵已被算入桃数
			return true
		end
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.yizhiyy_mianbaoren = 0

--------------------------------------------------
--卓识
--------------------------------------------------

sgs.ai_skill_invoke.zhuoshi = function(self, data)
	return true
end

--[[sgs.ai_skill_playerchosen.zhuoshi = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "defense")
	for _, p in ipairs(targetlist) do
		if self:isFriend(p) and not hasManjuanEffect(p) then
			return p
		end
	end
	return nil
end]]

sgs.ai_skill_use["@@zhuoshi!"] = function(self, prompt, method)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local can_give_cards = {}
	for _, card in ipairs(cards) do		--统计所有牌中可交出的牌
		if card:isKindOf("BasicCard") and self.player:getMark("zhuoshi_BasicCard") == 0 then
			table.insert(can_give_cards, card)
		elseif card:isKindOf("TrickCard") and self.player:getMark("zhuoshi_TrickCard") == 0 then
			table.insert(can_give_cards, card)
		elseif card:isKindOf("EquipCard") and self.player:getMark("zhuoshi_EquipCard") == 0 then
			table.insert(can_give_cards, card)
		end
	end
	
	for _, friend in ipairs(self.friends_noself) do	--扫描可交出的牌是否有队友需要
		if not self.player:canEffect(friend, "zhuoshi") then continue end
		for _, card in ipairs(can_give_cards) do
			if self:needCard(friend, card) then		--新函数，返回某角色是否需要某张牌（根据cardneed）
				return "#zhuoshi:"..card:getId()..":->"..friend:objectName()
			end
		end
	end
	
	if self:getOverflow() > 0 and #can_give_cards > 0 then	--手牌溢出，则尽量给牌
		for _, friend in ipairs(self.friends_noself) do
			if not self.player:canEffect(friend, "zhuoshi") then continue end
			if self:canDraw(friend) then
				return "#zhuoshi:"..can_give_cards[1]:getId()..":->"..friend:objectName()
			end
		end
	end
	
	if table.contains(can_give_cards, cards[1]) then		--尝试交出最不需要的牌
		for _, friend in ipairs(self.friends_noself) do
			if not self.player:canEffect(friend, "zhuoshi") then continue end
			if self:canDraw(friend) then
				return "#zhuoshi:"..cards[1]:getId()..":->"..friend:objectName()
			end
		end
	end
	
	return "#zhuoshi:"..cards[1]:getId()..":"
end

sgs.ai_playerchosen_intention.zhuoshi = function(self, from, to)
	local intention = -10
	if (self:needKongcheng(to) and to:isKongcheng()) or hasManjuanEffect(to) then
		intention = 0
	end
	sgs.updateIntention(from, to, intention)
end

sgs.ai_cardneed.zhuoshi = function(to, card, self)
	return card:isKindOf("TrickCard")
end

--------------------------------------------------
--法棍
--------------------------------------------------

sgs.ai_cardneed.fagun = function(to, card, self)
	return card:isKindOf("BasicCard") and card:isRed()
end




--嘲讽
sgs.ai_chaofeng.liantai_bingyuanlangwang = 0

--------------------------------------------------
--逐猎
--------------------------------------------------

sgs.ai_cardneed.zhulie = function(to, card, self)
	return card:isKindOf("Slash")
end

--------------------------------------------------
--混音
--------------------------------------------------

sgs.ai_skill_invoke.hunyin = function(self, data)
	return true
end

sgs.ai_skill_invoke["hunyin_throw"] = function(self, data)
	local first = sgs.Sanguosha:getCard(self.room:getDrawPile():at(1))	--反向置于
	local second = sgs.Sanguosha:getCard(self.room:getDrawPile():at(0))	--反向置于
	if not self.player:getJudgingArea():isEmpty() then
		local last_judge = self.player:getJudgingArea():last()	--获取判定区最后一张牌（将第一个判定）
		if last_judge and last_judge:isKindOf("Indulgence") and first:getSuit() ~= sgs.Card_Heart then
			return true
		end
		if last_judge and last_judge:isKindOf("SupplyShortage") and first:getSuit() ~= sgs.Card_Club then
			return true
		end
		if last_judge and last_judge:isKindOf("Lightning") and first:getSuit() == sgs.Card_Spade and first:getNumber() >= 2 and first:getNumber() <= 9 then
			return true
		end
		return false
	else
		if (first:isKindOf("ExNihilo") or second:isKindOf("ExNihilo")) and not self:willSkipPlayPhase() then
			return false
		end
		local average_use_value = (self:getUseValue(first) + self:getUseValue(second)) / 2
		return average_use_value > 6
	end
	return false
end

sgs.ai_cardneed.hunyin = function(to, card, self)
	return card:isKindOf("Slash")
end




--嘲讽
sgs.ai_chaofeng.xingzhigumiya_mengmao = 0

--------------------------------------------------
--衔尾
--------------------------------------------------

function canUseXianwei(player, subcards, N)
	local card = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
	for _,cd in ipairs(subcards) do
		if card:subcardsLength() == N then
			break
		end
		card:addSubcard(cd)
	end
	card:setSkillName("xianwei")
	local can_use = player:canUse(card)
	card:deleteLater()
	return can_use
end

local xianwei_skill={}
xianwei_skill.name="xianwei"
table.insert(sgs.ai_skills,xianwei_skill)
xianwei_skill.getTurnUseCard=function(self)
	if self.player:getMark("&xianwei_count!") <= 2 and self.player:isWounded() and not self.player:isKongcheng() then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
	
		if self.player:getMark("&xianwei_count!") == 0 then	--第一次
			local card
		
			self:sortByUseValue(cards,true)
		
			for _,acard in ipairs(cards) do
				if not acard:isKindOf("ExNihilo") and (self:getDynamicUsePriority(acard) <= 9 or self:getOverflow() > 0) then
					card = acard
				end
			end
		
			if not card then return nil end
			if not canUseXianwei(self.player, cards, 1) then return nil end	--出于莫名原因，吃了变频②的自肃电脑还能用衔尾，这里用于排除
			local card_str = ("ex_nihilo:xianwei[%s:%s]=%d"):format("to_be_decided", 0, card:getEffectiveId())
			local skillcard = sgs.Card_Parse(card_str)
		
			assert(skillcard)
		
			return skillcard
		elseif self.player:getMark("&xianwei_count!") == 1 and self.player:getHandcardNum() >= 2 then	--第二次
			local discards = dimeng_discard(self, 2, cards)
			if #discards > 0 then
				local total_use_value = 0
				for _, id in ipairs(discards) do
					total_use_value = total_use_value + self:getUseValue(sgs.Sanguosha:getCard(id))
				end
				
				if total_use_value <= 10 and canUseXianwei(self.player, discards, 2) then
					local card_str = ("ex_nihilo:xianwei[%s:%s]=%d+%d"):format("to_be_decided", 0, discards[1], discards[2])
					local skillcard = sgs.Card_Parse(card_str)
				
					assert(skillcard)
				
					return skillcard
				end
			end
		elseif self.player:getMark("&xianwei_count!") == 2 and self.player:getHandcardNum() >= 3 then	--第三次
			local discards = dimeng_discard(self, 3, cards)
			if #discards > 0 then
				local total_use_value = 0
				for _, id in ipairs(discards) do
					total_use_value = total_use_value + self:getUseValue(sgs.Sanguosha:getCard(id))
				end
				
				if total_use_value <= 10 and canUseXianwei(self.player, discards, 3) then
					local card_str = ("ex_nihilo:xianwei[%s:%s]=%d+%d+%d"):format("to_be_decided", 0, discards[1], discards[2], discards[3])
					local skillcard = sgs.Card_Parse(card_str)
				
					assert(skillcard)
				
					return skillcard
				end
			end
		elseif self.player:getMark("&xianwei_count!") == 3 and self.player:getHandcardNum() >= 4 then	--第四次
			local discards = dimeng_discard(self, 4, cards)
			if #discards > 0 then
				local total_use_value = 0
				for _, id in ipairs(discards) do
					total_use_value = total_use_value + self:getUseValue(sgs.Sanguosha:getCard(id))
				end
				
				if total_use_value <= 10 and canUseXianwei(self.player, discards, 4) then
					local card_str = ("ex_nihilo:xianwei[%s:%s]=%d+%d+%d+%d"):format("to_be_decided", 0, discards[1], discards[2], discards[3], discards[4])
					local skillcard = sgs.Card_Parse(card_str)
				
					assert(skillcard)
				
					return skillcard
				end
			end
		end
	end
end




--嘲讽
sgs.ai_chaofeng.dongaili_xingtu = 0

--------------------------------------------------
--咏星
--------------------------------------------------

sgs.ai_cardneed.hunyin = function(to, card, self)
	return card:isKindOf("AOE") or card:isKindOf("Duel")
end

--------------------------------------------------
--扬歌
--------------------------------------------------

sgs.ai_skill_invoke.yangge = function(self, data)
	self.yangge_type = false
	
	local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
	savage_assault:setSkillName("yangge")
	if not self.player:faceUp() and self:willUse(self.player, savage_assault) then
		savage_assault:deleteLater()
		return true
	end
	
	if not self.player:isKongcheng() then
		local god_salvation = sgs.Sanguosha:cloneCard("god_salvation", sgs.Card_NoSuit, 0)
		god_salvation:setSkillName("yangge")
		if self:willUse(self.player, god_salvation) then
			god_salvation:deleteLater()
			self.yangge_type = true
			return true
		end
		god_salvation:deleteLater()
	end
	
	local has_weak_enemy = false
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) and enemy:getHp() == 1 then
			has_weak_enemy = true
		end
	end
	if has_weak_enemy and self:willUse(self.player, savage_assault) then
		savage_assault:deleteLater()
		return true
	end
	
	savage_assault:deleteLater()
	
	return false
end

sgs.ai_skill_discard["yangge"] = function(self, discard_num, min_num, optional, include_equip)	--yun
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local to_discard = {}
	if self.yangge_type == true then
		to_discard = dimeng_discard(self, 1, cards)
	end
	return to_discard
end




--嘲讽
sgs.ai_chaofeng.nanyinnai_maomaotou = 0

--------------------------------------------------
--隐游
--------------------------------------------------

sgs.ai_skill_use["@@yinyou"] = function(self, prompt, method)
	if self.player:getHandcardNum() < 2 then return "" end
    local card_ids = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local card, target = self:getCardNeedPlayer(cards, false)
	if target and target:isAlive() and card and self.player:canEffect(target, "yinyou") then	--有需要某牌的队友
		table.insert(card_ids, card:getEffectiveId())
		table.removeOne(cards, card)
		for _, hcard in ipairs(cards) do	--再给其所需的牌
			for _, askill in sgs.qlist(target:getVisibleSkillList(true)) do
				local callback = sgs.ai_cardneed[askill:objectName()]
				if type(callback)=="function" and callback(target, hcard, self) then
					table.insert(card_ids, hcard:getEffectiveId())
					table.removeOne(cards, hcard)
					break
				end
			end
			if #card_ids >= 2 and (self:getOverflow() - #card_ids) <= 0 then
				break
			end
		end
		self:sortByKeepValue(cards)
		cards = sgs.reverse(cards)
		for _,acard in ipairs(cards) do
			if (#cards > 2 or self:isWeak()) and (acard:isKindOf("Peach") or acard:isKindOf("Jink")) then	--从可给牌中剔除闪桃
				table.removeOne(cards, acard)
			end
		end
		cards = sgs.reverse(cards)
		for _,acard in ipairs(cards) do
			if #cards > 2 and self.player:hasSkill("xiange") and acard:isKindOf("TrickCard") then	--可以的话剔除一张最没用的锦囊
				table.removeOne(cards, acard)
				break
			end
		end
		for _,acard in ipairs(cards) do
			if not table.contains(card_ids, acard:getEffectiveId()) and (#card_ids < 2 or (self:getOverflow() - #card_ids) > 0) then
				table.insert(card_ids, acard:getEffectiveId())
			end
		end
		if #card_ids >= 2 then
			return "#yinyou:"..table.concat(card_ids, "+")..":->"..target:objectName()
		end
	elseif #self.friends_noself > 0 then	--没有需要某牌的队友
		self:sortByKeepValue(cards)
		cards = sgs.reverse(cards)
		for _,acard in ipairs(cards) do
			if (#cards > 2 or self:isWeak()) and (acard:isKindOf("Peach") or acard:isKindOf("Jink")) then	--从可给牌中剔除闪桃
				table.removeOne(cards, acard)
			end
		end
		cards = sgs.reverse(cards)
		for _,acard in ipairs(cards) do
			if #cards > 2 and self.player:hasSkill("xiange") and acard:isKindOf("TrickCard") then	--可以的话剔除一张最没用的锦囊
				table.removeOne(cards, acard)
				break
			end
		end
		if #cards >= 2 then
			local give_ids = dimeng_discard(self, math.max(2, self:getOverflow()), cards)
			if #give_ids >= 2 then
				self:sort(self.friends_noself, "defense")
				for _, friend in ipairs(self.friends_noself) do
					if self:canDraw(friend) and self.player:canEffect(friend, "yinyou") then
						return "#yinyou:"..table.concat(give_ids, "+")..":->"..friend:objectName()
					end
				end
			end
		end
	end
end

sgs.ai_playerchosen_intention.yinyou = function(self, from, to)
	local intention = -10
	if (self:needKongcheng(to) and to:isKongcheng()) or hasManjuanEffect(to) then
		intention = 0
	end
	sgs.updateIntention(from, to, intention)
end

--------------------------------------------------
--闲歌
--------------------------------------------------

local xiange_skill = {}
xiange_skill.name = "xiange"
table.insert(sgs.ai_skills, xiange_skill)
xiange_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#xiange") < 1 then
		return sgs.Card_Parse("#xiange:.:")
	end
end
sgs.ai_skill_use_func["#xiange"] = function(card, use, self)
	local target, card_str
	local targets, friends, enemies = {}, {}, {}

	local hcards = self.player:getHandcards()
	local hand_trick
	local just_use = false
	for _, hcard in sgs.qlist(hcards) do
		if hcard:isKindOf("TrickCard") then
			hand_trick = true
			card_str = "#xiange:" .. hcard:getId() .. ":"
		end
	end
	if (hand_trick and self:getOverflow() > 0) or (self.player:getHp() > 3 and self:getOverflow() < 0) then
		just_use = true
	end
	if hand_trick or self.player:getHp() > 3 then
		if not card_str then card_str = "#xiange:.:" end
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self.player:canSlash(player) then
				table.insert(targets, player)

				if self:isFriend(player) then
					table.insert(friends, player)
				elseif self:isEnemy(player) and not self:doNotDiscard(player, "he", nil, 2) then
					table.insert(enemies, player)
				end
			end
		end
	else
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self.player:distanceTo(player) <= 1 then
				table.insert(targets, player)

				if self:isFriend(player) then
					table.insert(friends, player)
				elseif self:isEnemy(player) and not self:doNotDiscard(player, "he", nil, 2) then
					table.insert(enemies, player)
				end
			end
		end
	end

	if #targets == 0 then return end
	for _, player in ipairs(targets) do
		if not player:containsTrick("YanxiaoCard") and player:containsTrick("lightning") and self:getFinalRetrial(player) == 2 then
			target = player
			break
		end
	end
	if not target and #friends ~= 0 then
		for _, friend in ipairs(friends) do
			if not friend:containsTrick("YanxiaoCard") and not (friend:hasSkill("qiaobian") and not friend:isKongcheng())
			  and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
				target = friend
				break
			end
			if friend:getCards("e"):length() > 1 and self:hasSkills(sgs.lose_equip_skill, friend) then
				target = friend
				break
			end
		end
	end
	if not target and #enemies > 0 then
		self:sort(enemies, "defense")
		for _, enemy in ipairs(enemies) do
			if enemy:containsTrick("YanxiaoCard") and (enemy:containsTrick("indulgence") or enemy:containsTrick("supply_shortage")) then
				target = enemy
				break
			end
			if self:getDangerousCard(enemy) then
				target = enemy
				break
			end
			if not enemy:hasSkill("tuntian+zaoxian") then
				target = enemy
				break
			end
		end
	end
	if not target and #enemies > 0 and just_use then
		self:sort(enemies, "defense")
		for _, enemy in ipairs(enemies) do
			if enemy:getCardCount(true) >= 2 then
				target = enemy
				break
			end
		end
	end

	if not target or not SkillCanTarget(target, self.player, "xiange") or not self.player:canEffect(target, "xiange") then return end
	if not card_str then
		if self:isFriend(target) and self.player:getHp() > 2 then card_str = "#xiange:.:" end
	end

	if card_str then
		if use.to then
			if self:isFriend(target) then
				if not use.isDummy then target:setFlags("xiangeOK") end
			end
			use.to:append(target)
		end
		card_str = card_str.."->"..target:objectName()
		--self.player:speak(card_str)
		use.card = sgs.Card_Parse(card_str)
	end
end

sgs.ai_cardneed.xiange = function(to, card, self)
	return card:isKindOf("TrickCard")
end

sgs.ai_use_priority["xiange"] = sgs.ai_use_priority.Dismantlement + 0.1

sgs.ai_card_intention.xiange = function(self, card, from, tos)
	if #tos > 0 then
		for _,to in ipairs(tos) do
			if to:hasFlag("xiangeOK") then
				to:setFlags("-xiangeOK")
				sgs.updateIntention(from, to, -10)
			elseif not self:isFriend(from, to) then
				sgs.updateIntention(from, to, 10)
			end
		end
	end
	return 0
end




--嘲讽
sgs.ai_chaofeng.beiyouxiang_motaishouke = 0

--------------------------------------------------
--作业
--------------------------------------------------

sgs.ai_skill_playerchosen.zuoye = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	local to = findPlayerByFlag(self.room, "zuoye_target_AI")
	if to then		--选择第二步
		local targets = sgs.SPlayerList()
		for _, vic in sgs.qlist(self.room:getOtherPlayers(to)) do
			if to:canSlash(vic) then
				targets:append(vic)
			end
		end
		if not targets:isEmpty() then
			targets = sgs.QList2Table(targets)
			self:sort(targets, "defense")
			for _, target in ipairs(targets) do
				if self:isEnemy(target) then
					return target
				end
			end
		end
	else			--选择第一步
		self:sort(targetlist, "defense")
		targetlist = sgs.reverse(targetlist)
		
		for _, p in ipairs(targetlist) do					--被翻面的队友
			if self:isFriend(p) and not p:faceUp() then
				return p
			end
		end
		for _, p in ipairs(targetlist) do					--不能出杀的敌人
			if self:isEnemy(p) and p:faceUp() then
				local targets = sgs.SPlayerList()
				for _, vic in sgs.qlist(self.room:getOtherPlayers(p)) do
					if p:canSlash(vic) then
						targets:append(vic)
					end
				end
				if targets:isEmpty() then
					return p
				end
			end
		end
		for _, p in ipairs(targetlist) do					--有明杀的队友
			if self:isFriend(p) and getCardsNum("Slash", p, self.player) > 0 then
				for _, vic in sgs.qlist(self.room:getOtherPlayers(p)) do
					if p:canSlash(vic) then
						return p
					end
				end
			end
		end
		for _, p in ipairs(targetlist) do					--未知牌多的队友
			local unknown_card_count = 0
			for _, cd in sgs.qlist(p:getHandcards()) do
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), p:objectName())
				if not cd:hasFlag("visible") then
					unknown_card_count = unknown_card_count + 1
				end
			end
			if self:isFriend(p) and unknown_card_count >= 3 then
				for _, vic in sgs.qlist(self.room:getOtherPlayers(p)) do
					if p:canSlash(vic) then
						return p
					end
				end
			end
		end
		for _, p in ipairs(targetlist) do					--有容易出杀技能的队友
			if self:isFriend(p) and p:hasSkills("quanneng|fenxin_S|jichi|zhuge") then
				for _, vic in sgs.qlist(self.room:getOtherPlayers(p)) do
					if p:canSlash(vic) then
						return p
					end
				end
			end
		end
		for _, p in ipairs(targetlist) do					--能杀虚弱队友的敌人
			if self:isEnemy(p) and p:faceUp() then
				local targets = sgs.SPlayerList()
				for _, vic in sgs.qlist(self.room:getOtherPlayers(p)) do
					if p:canSlash(vic) and self:isFriend(p, vic) and self:isWeak(vic) then
						return p
					end
				end
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.zuoye = function(self, from, to)
	local target = findPlayerByFlag(self.room, "zuoye_target_AI")
	if target then		--第二步
		if not target:faceUp() then		--若第一步的玩家为背面则选谁都无所谓
			sgs.updateIntention(from, to, 10)
		end
	else				--第一步
		if not to:faceUp() then			--这里只计选背面角色的情况为友好（为了给人类玩家容错）
			sgs.updateIntention(from, to, -10)
		end
	end
end




--嘲讽
sgs.ai_chaofeng.ximoyou_jiweimowang = -2

--------------------------------------------------
--阴谋
--------------------------------------------------

local yinmou_skill={}
yinmou_skill.name="yinmou"
table.insert(sgs.ai_skills,yinmou_skill)
yinmou_skill.getTurnUseCard=function(self)
	if self.player:getMark("yinmou") == 1 then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards) do
		if acard:isBlack() and acard:isKindOf("TrickCard") and (self:getDynamicUsePriority(acard) <= 9 or self:getOverflow() > 0) then
			card = acard
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("duel:yinmou[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end

sgs.ai_cardneed.yinmou = function(to, card, self)
	return card:isBlack() and card:isKindOf("TrickCard")
end

--------------------------------------------------
--幽炼
--------------------------------------------------

sgs.ai_skill_invoke.youlian = function(self, data)
	return true		--就烧，魂就完事了
end

sgs.ai_skill_cardask["@youlian_give"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards, self:isFriend(self.room:getCurrent()))
	for _, card in ipairs(cards) do
		if not card:isKindOf("BasicCard") then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end




--嘲讽
sgs.ai_chaofeng.shuangyue_yuezhishuangzi = 0

--------------------------------------------------
--月盈
--------------------------------------------------

sgs.ai_skill_use["@@yueying"] = function(self, prompt, method)
	self:updatePlayers()
	
	local data = self.player:getTag("yueying_data")
	local move = data:toMoveOneTime()
	
	if self.player:getChangeSkillState("yueying") <= 1 then		--月盈杀
		if move.card_ids:length() > 2 and not (self:willSkipPlayPhase() and self:getOverflow() > 0) then
			return ""
		elseif move.card_ids:length() == 2 and self.player:getPhase() ~= sgs.Player_NotActive then
			if (self.player:getPhase() < sgs.Player_Play and not self:willSkipPlayPhase()) or self.player:getPhase() == sgs.Player_Play then
				for _,card in sgs.qlist(self.player:getCards("h")) do
					if card:isKindOf("ExNihilo") or card:isKindOf("IronChain") then
						return ""
					end
				end
			end
			
			local average_use_value = 0
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("ExNihilo") and not self:willSkipPlayPhase() then
					return ""
				end
				average_use_value = average_use_value + self:getUseValue(sgs.Sanguosha:getCard(id))
			end
			average_use_value = average_use_value / move.card_ids:length()
			
			if average_use_value > 8 then
				return ""
			end
		elseif move.card_ids:length() == 1 then
			local card = sgs.Sanguosha:getCard(move.card_ids:first())
			if (card:isKindOf("Peach") or card:isKindOf("Analeptic") or card:isKindOf("Jink")) and self:isWeak() then
				return ""
			end
		end
		
		local target_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if c:hasFlag("yueyingcard") then
				target_card:addSubcard(c:getId())
			end
		end
		target_card:setSkillName("yueying")
		if not target_card or target_card:subcardsLength() == 0 then return "" end
		
		local to = self:findPlayerToSlash(false, target_card, nil, false)		--距离限制、卡牌、角色限制、必须选择
		if to then
			local result = target_card:toString() .. "->" .. to:objectName()
			target_card:deleteLater()
			return result
		end
		target_card:deleteLater()
	else											--月盈无中生有
		if move.card_ids:length() < 2 then
			return "#yueying:.:->"..self.player:objectName()
		elseif move.card_ids:length() == 2 then
			if (self.player:getPhase() < sgs.Player_Play and not self:willSkipPlayPhase() and self.player:getPhase() ~= sgs.Player_NotActive) or self.player:getPhase() == sgs.Player_Play then
				for _,card in sgs.qlist(self.player:getCards("h")) do
					if card:isKindOf("ExNihilo") or card:isKindOf("IronChain") then
						return ""
					end
				end
			end
			
			local average_use_value = 0
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("ExNihilo") and not self:willSkipPlayPhase() then
					return ""
				end
				average_use_value = average_use_value + self:getUseValue(sgs.Sanguosha:getCard(id))
			end
			average_use_value = average_use_value / move.card_ids:length()
			if average_use_value < 6 then
				return "#yueying:.:->"..self.player:objectName()
			end
		end
		return ""
	end
end




--嘲讽
sgs.ai_chaofeng.youte_lianxinmonv = -1

--------------------------------------------------
--链心
--------------------------------------------------

sgs.ai_skill_playerchosen.lianxin = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	for _, p in ipairs(targetlist) do
		if p:objectName() == self.player:objectName() and self.player:isWounded() then
			return p
		end
	end
	self:sort(targetlist, "defense")
	for _, p in ipairs(targetlist) do
		if self:isEnemy(p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.lianxin = function(self, data)
	local objname = string.sub(data:toString(), 8, -1)	--截取choice:后面的部分(即player:objectName())
	local to = findPlayerByObjName(self.room, objname)
	if to and self:isFriend(to) then
		return true
	end
	return false
end

--------------------------------------------------
--惑炎
--------------------------------------------------

sgs.ai_skill_use["@@huoyan"] = function(self, prompt, method)
	if self.player:isKongcheng() then
		return "."
	end
	local targets = sgs.SPlayerList()
	for _, vic in sgs.qlist(self.room:getAlivePlayers()) do
		local fire_attack_card = sgs.Sanguosha:cloneCard("fire_attack")
		fire_attack_card:setSkillName("huoyan")
		if fire_attack_card:isAvailable(self.player) and not self.room:isProhibited(self.player, vic, fire_attack_card) and fire_attack_card:targetFilter(sgs.PlayerList(), vic, self.player) and self:damageIsEffective(vic, sgs.DamageStruct_Fire, self.player) then
			targets:append(vic)
		end
		fire_attack_card:deleteLater()
	end
	if targets:isEmpty() then
		return "."
	end
	local over_flow_cards = math.max(0, self:getOverflow())
	local success_rate = 0.25
	local suits = {}
	for _, card in sgs.qlist(self.player:getCards("h")) do		--按顺序记录首次出现的花色以及对应牌
		local suit_str = card:getSuitString()
		if not table.contains(suits, suit_str) then
			table.insert(suits, suit_str)
		end
	end
	success_rate = success_rate * #suits
	local base_value = (2.5 + over_flow_cards - 2*success_rate)*10	--最低收益门槛：2.5牌（跳回合代价）+弃牌数-2*成功率；其中1牌价值为10
	local nice_target = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Fire, targets, true, base_value, false)
	if nice_target then
		return "#huoyan:.:->"..nice_target:objectName()
	end
	return "."
end



--嘲讽
sgs.ai_chaofeng.mien_duobiannvpu = 1

--------------------------------------------------
--全能？
--------------------------------------------------

local quanneng_skill = {}
quanneng_skill.name = "quanneng"
table.insert(sgs.ai_skills, quanneng_skill)
quanneng_skill.getTurnUseCard = function(self, inclusive)
	self:updatePlayers()
	if self.player:getMark("quanneng_used") > 0 then return end
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(handcards ,sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(handcards, true)
	local equipments = sgs.QList2Table(self.player:getCards("e"))
	self:sortByUseValue(equipments, true)
	local basic_cards = {}
	local basic_cards_count = 0
	local non_basic_cards = {}
	local use_cards = {}
	
	for _,c in ipairs(handcards) do
		if c:isKindOf("BasicCard") and not c:isKindOf("Peach") then
			basic_cards_count = basic_cards_count + 1
			table.insert(basic_cards, c:getEffectiveId())
		else
			table.insert(non_basic_cards, c:getEffectiveId())
		end
	end
	for _,e in ipairs(equipments) do
		if e:isKindOf("OffensiveHorse") then
			table.insert(non_basic_cards, e:getEffectiveId())
		end
		if self.player:hasArmorEffect("silver_lion") and self.player:isWounded() and self.player:getLostHp() >= 2 and e:isKindOf("SilverLion") then
			table.insert(non_basic_cards, e:getEffectiveId())
		end
	end
	if basic_cards_count < 3 then return end
	
	--if self.player:getMark("@quannengUsed") >= 3 then
		if #basic_cards > 0 then
			table.insert(use_cards, basic_cards[1])
		end
		if #use_cards == 0 then return end
	--[[else
		if #basic_cards > 0 and #non_basic_cards > 0 then
			table.insert(use_cards, basic_cards[1])
			table.insert(use_cards, non_basic_cards[1])
		elseif #basic_cards > 1 and #non_basic_cards == 0 then
			table.insert(use_cards, basic_cards[1])
			table.insert(use_cards, basic_cards[2])
		end
		if #use_cards ~= 2 then return end
	end]]
	
	if (self:isWeak() or self.player:getHp() <= 1) and self.player:isWounded() then
		return sgs.Card_Parse("#quanneng:" .. table.concat(use_cards, "+") .. ":" .. "peach")
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	if self:getCardsNum("Slash") > 1 and not slash:isAvailable(self.player) then
		for _, enemy in ipairs(self.enemies) do
			if ((enemy:getHp() < 3 and enemy:getHandcardNum() < 3) or (enemy:getHandcardNum() < 2)) and self.player:canSlash(enemy) and not self:slashProhibit(slash, enemy, self.player)
				and self:slashIsEffective(slash, enemy, self.player) and sgs.isGoodTarget(enemy, self.enemies, self, true) then
				return sgs.Card_Parse("#quanneng:" .. table.concat(use_cards, "+") .. ":" .. "analeptic")
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and sgs.isGoodTarget(enemy, self.enemies, self, true) then
			local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash")
			local fire_slash = sgs.Sanguosha:cloneCard("fire_slash")
			local ice_slash = sgs.Sanguosha:cloneCard("ice_slash")
			self.is_ice_slash = true
			if not self:slashProhibit(ice_slash, enemy, self.player) and self:slashIsEffective(ice_slash, enemy, self.player) then
				ice_slash:deleteLater()
				self.is_ice_slash = false
				return sgs.Card_Parse("#quanneng:" .. table.concat(use_cards, "+") .. ":" .. "ice_slash")
			end
			self.is_ice_slash = false
			if not self:slashProhibit(fire_slash, enemy, self.player) and self:slashIsEffective(fire_slash, enemy, self.player) then
				fire_slash:deleteLater()
				return sgs.Card_Parse("#quanneng:" .. table.concat(use_cards, "+") .. ":" .. "fire_slash")
			end
			if not self:slashProhibit(thunder_slash, enemy, self.player) and self:slashIsEffective(thunder_slash, enemy, self.player) then
				thunder_slash:deleteLater()
				return sgs.Card_Parse("#quanneng:" .. table.concat(use_cards, "+") .. ":" .. "thunder_slash")
			end
			if not self:slashProhibit(slash, enemy, self.player) and self:slashIsEffective(slash, enemy, self.player) then
				slash:deleteLater()
				return sgs.Card_Parse("#quanneng:" .. table.concat(use_cards, "+") .. ":" .. "slash")
			end
			ice_slash:deleteLater()
			fire_slash:deleteLater()
			thunder_slash:deleteLater()
		end
	end
	slash:deleteLater()
	if self.player:isWounded() and (self:getOverflow() > 0 or self.player:getPhase() ~= sgs.Player_Play) then
		return sgs.Card_Parse("#quanneng:" .. table.concat(use_cards, "+") .. ":" .. "peach")
	end
end

sgs.ai_skill_use_func["#quanneng"] = function(card, use, self)
	if self.player:getMark("quanneng_used") > 0 then return end
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local quannengcard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	quannengcard:setSkillName("quanneng")
	self:useBasicCard(quannengcard, use)
	quannengcard:deleteLater()
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["quanneng"] = 3
sgs.ai_use_value["quanneng"] = 3

sgs.ai_view_as["quanneng"] = function(card, player, card_place, class_name)
	if player:getMark("quanneng_used") > 0 then return end
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash"
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local no_have = true
	local cards = player:getCards("he")
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			cards:prepend(sgs.Sanguosha:getCard(id))
		end
	end
	for _,c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			no_have = false
			break
		end
	end
	if not no_have then return end
	if class_name == "Peach" and player:getMark("Global_PreventPeach") > 0 then return end
	
	local handcards = sgs.QList2Table(player:getCards("h"))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(handcards ,sgs.Sanguosha:getCard(id))
		end
	end
	local equipments = sgs.QList2Table(player:getCards("e"))
	local basic_cards = {}
	local non_basic_cards = {}
	local use_cards = {}
	
	for _,c in ipairs(handcards) do
		if c:isKindOf("BasicCard") and not c:isKindOf("Peach") then
			table.insert(basic_cards, c:getEffectiveId())
		else
			table.insert(non_basic_cards, c:getEffectiveId())
		end
	end
	for _,e in ipairs(equipments) do
		if not (e:isKindOf("Armor") or e:isKindOf("DefensiveHorse")) and not (e:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
			table.insert(non_basic_cards, e:getEffectiveId())
		end
		if player:hasArmorEffect("silver_lion") and player:isWounded() and player:getLostHp() >= 2 and e:isKindOf("SilverLion") then
			table.insert(non_basic_cards, e:getEffectiveId())
		end
	end
	
	--if player:getMark("@quannengUsed") >= 3 then
		if #basic_cards > 0 then
			table.insert(use_cards, basic_cards[1])
		end
		if #use_cards == 0 then return end
	--[[else
		if #basic_cards > 0 and #non_basic_cards > 0 then
			table.insert(use_cards, basic_cards[1])
			table.insert(use_cards, non_basic_cards[1])
		elseif #basic_cards > 1 and #non_basic_cards == 0 then
			table.insert(use_cards, basic_cards[1])
			table.insert(use_cards, basic_cards[2])
		end
		if #use_cards ~= 2 then return end
	end]]
	
	--if player:getMark("@quannengUsed") >= 3 then
		return (name..":quanneng[%s:%s]=%d"):format(sgs.Card_NoSuit, 0, use_cards[1])
	--[[else
		return (name..":quanneng[%s:%s]=%d+%d"):format(sgs.Card_NoSuit, 0, use_cards[1], use_cards[2])
	end]]
end

sgs.ai_cardneed.quanneng = function(to, card, self)
	return card:isKindOf("BasicCard")
end



--嘲讽
sgs.ai_chaofeng.huaman_wunianhuajiang = 1

--------------------------------------------------
--结硕
--------------------------------------------------

local jieshuo_skill={}
jieshuo_skill.name="jieshuo"
table.insert(sgs.ai_skills,jieshuo_skill)
jieshuo_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#jieshuo") < 1 and not self.player:isKongcheng() then
		return sgs.Card_Parse("#jieshuo:.:")
	end
end
sgs.ai_skill_use_func["#jieshuo"] = function(card, use, self)
	self:sort(self.friends, "hp")
	for _, friend in ipairs(self.friends) do
		if friend:isWounded() and SkillCanTarget(friend, self.player, "jieshuo") and self.player:canEffect(friend, "jieshuo") and not self:needToLoseHp(friend, self.player, false, false, true) then	--needToLoseHp的第五个参数为真则考虑回血后情况
			local cards = self.player:getCards("h")
			cards = sgs.QList2Table(cards)
			local ids = dimeng_discard(self, 1, cards)
			if use.to then
				use.to:append(friend)
			end
			card_str = "#jieshuo:"..ids[1]..":->"..friend:objectName()
			use.card = sgs.Card_Parse(card_str)
			break
		end 
	end
end

sgs.ai_use_priority["jieshuo"] = 8

sgs.ai_card_intention.jieshuo = -10

--------------------------------------------------
--春泥
--------------------------------------------------

sgs.ai_skill_use["@@chunni"] = function(self, prompt)
    local targets = {}
    for _, friend in ipairs(self.friends) do
        if friend:isWounded() and friend:objectName() ~= self.player:objectName() and self.player:canEffect(friend, "chunni") then
            table.insert(targets, friend:objectName())
        end 
    end
	if #targets > 0 then
		return "#chunni:.:->"..table.concat(targets, "+")
	end
end



--嘲讽
sgs.ai_chaofeng.xibeier_sanjueweibian = 0

--------------------------------------------------
--化武
--------------------------------------------------

sgs.ai_skill_invoke.huawu = function(self, data)
	if self.player:getEquips():length() <= 3 then
		return true
	end
end

sgs.ai_skill_askforag["huawu"] = function(self, card_ids)	--【新增】化武选牌
	local first, second, third
	self:sortIdsByValue(card_ids, "use", false)
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		local equip_index = card:getRealCard():toEquipCard():location()
		if self.player:getEquip(equip_index) == nil then
			if not first and (((card:isKindOf("SilverLion") or (card:isKindOf("Ssxuehe") and self.player:getLostHp() > 1)) and self.player:isWounded() and not self:needToLoseHp()) or card:isKindOf("Ssxianghu")) then	--优先用
				first = id
			elseif not second and ((card:isKindOf("Weapon") and card:getRealCard():toWeapon():getRange() > 1) or card:isKindOf("OffensiveHorse")) then	--起码拿距离
				second = id
			elseif not third and not (card:isKindOf("Lianglunche")) then	--至少别用
				third = id
			end
			
			if first and second and third then
				break
			end
		end
	end
	return first or second or third or card_ids[1]
end



--嘲讽
sgs.ai_chaofeng.leidi_cuilianzhiyuan = 0

--------------------------------------------------
--浴火
--------------------------------------------------

sgs.ai_skill_choice.yuhuo = function(self, choices)
	if self:isWeak() and self.player:isWounded() then
		return "yuhuo_recover"
	end
	return "yuhuo_draw"
end

--------------------------------------------------
--凭代
--------------------------------------------------

sgs.ai_skill_invoke.pingdai = function(self, data)
	local from = data:toPlayer()
	if from then
		if self:isFriend(from) then
			if self:needToThrowArmor(from) or self:hasCrossbowEffect(from) or from:hasSkills(double_slash_skill) or self:hasTemporaryCard(from) then
				return true
			end
			if from:objectName() == self.player:objectName() then
				return getCardsNum("TrickCard", self.player, self.player, true) + getCardsNum("EquipCard", self.player, self.player, true) > 0
			else
				--if (from:getHandcardNum() >= 4 or self:getOverflow(from) > 0) and not self:isWeak(from) then
				if from:getHandcardNum() >= 3 or self:getOverflow(from) > 0 or getCardsNum("TrickCard", from, self.player, true) + getCardsNum("EquipCard", from, self.player, true) > 0 then
					return true
				end
			end
		elseif self:isEnemy(from) and not self:needToThrowArmor(from) and not self:hasCrossbowEffect(from) and not from:hasSkills(double_slash_skill) and not self:hasTemporaryCard(from) then
			--if from:getHandcardNum() <= 2 or (self:getOverflow(from) < 0 and self:isWeak(from)) then
				return true
			--end
		elseif not self:isFriend(from) and not self:isEnemy(from) then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardask["@pingdai_choose"] = function(self, data, pattern, target)
	local source = data:toPlayer()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByCardNeed(cards, false)
	local first, second
	for _, card in ipairs(cards) do
		if not first and ((card:isKindOf("BasicCard") and self:isEnemy(source)) or (not card:isKindOf("BasicCard") and self:isFriend(source))) then
			first = card:getEffectiveId()
		elseif not second then
			second = card:getEffectiveId()
		end
		if first and second then
			break
		end
	end
	return "$"..(first or second)
end



--嘲讽
sgs.ai_chaofeng.lafa_duoluotianshi = 0

--------------------------------------------------
--废宅
--------------------------------------------------

sgs.ai_skill_choice.feizhai = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if table.contains(items, "5") then	--废宅总选最多张
			return "5"
		elseif table.contains(items, "4") then
			return "4"
		elseif table.contains(items, "3") then
			return "3"
		elseif table.contains(items, "2") then
			return "2"
		elseif table.contains(items, "1") then
			return "1"
		end
		
		if self.shengguang_used then		--发动圣光的回合不用废宅
			self.shengguang_used = false
			return "cancel"
		end
		
		local will_use = false
		local has_equip_area = 0
		for i = 0, 4 do
			if self.player:hasEquipArea(i) then
				has_equip_area = has_equip_area + 1
			end
		end
		if has_equip_area >= 3 and self.player:getHandcardNum() - math.max(getCardsNum("Peach", self.player, self.player, true), self.player:getLostHp()) <= 3 and not self:willSkipPlayPhase() then
			will_use = true
		elseif has_equip_area > 0 and self:isWeak(self.player, true) and not self:willSkipPlayPhase() then
			will_use = true
		end
		if not will_use then
			return "cancel"
		end
		
		if table.contains(items, "jueyan1") and self:needToThrowArmor(self.player, true) then	--需要丢防具就直接废除防具
			return "jueyan1"
		end
		local not_value_location = {4,3,2,1,0}
		for _,card in sgs.qlist(self.player:getCards("he")) do
			if card:isKindOf("EquipCard") and table.contains(not_value_location, card:getRealCard():toEquipCard():location()) then
				table.removeOne(not_value_location, card:getRealCard():toEquipCard():location())
			end
		end
		for _, location in ipairs(not_value_location) do
			if table.contains(items, "jueyan"..location) then	--优先废除不能装备的栏位
				return "jueyan"..location
			end
		end
		if table.contains(items, "jueyan4") then
			return "jueyan4"
		elseif table.contains(items, "jueyan3") then
			return "jueyan3"
		elseif table.contains(items, "jueyan2") then
			return "jueyan2"
		elseif table.contains(items, "jueyan1") then
			return "jueyan1"
		elseif table.contains(items, "jueyan0") then
			return "jueyan0"
		elseif table.contains(items, "cancel") then
			return "cancel"
		end
	end
end

--------------------------------------------------
--萌生
--------------------------------------------------

sgs.ai_skill_choice.mengsheng = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local will_use = false
		local has_equip_area = 0
		for i = 0, 4 do
			if self.player:hasEquipArea(i) then
				has_equip_area = has_equip_area + 1
			end
		end
		if self.player:hasSkill("feizhai") then
			if has_equip_area == 0 or (has_equip_area < 3 and not self:isWeak(self.player, true)) then
				will_use = true
			end
		elseif not self:isWeak(self.player, true) then
			will_use = true
		end
		if self:getOverflow() > 0 and self.player:getHandcardNum() > 2 then
			will_use = true
		end
		if not will_use then
			return "cancel"
		end
		
		local value_location = {}
		for _,card in sgs.qlist(self.player:getCards("h")) do
			if card:isKindOf("EquipCard") and not table.contains(value_location, card:getRealCard():toEquipCard():location()) then
				table.insert(value_location, card:getRealCard():toEquipCard():location())
			end
		end
		for _, location in ipairs(value_location) do
			if table.contains(items, "jueyan"..location) then	--优先恢复能装备的栏位
				return "jueyan"..location
			end
		end
		if table.contains(items, "jueyan0") then
			return "jueyan0"
		elseif table.contains(items, "jueyan1") then
			return "jueyan1"
		elseif table.contains(items, "jueyan2") then
			return "jueyan2"
		elseif table.contains(items, "jueyan3") then
			return "jueyan3"
		elseif table.contains(items, "jueyan4") then
			return "jueyan4"
		elseif table.contains(items, "cancel") then
			return "cancel"
		end
	end
end

--------------------------------------------------
--圣光
--------------------------------------------------

sgs.ai_skill_invoke.shengguang = function(self, data)
	if self:isWeak(self.player, true) and getCardsNum("Peach", self.player, self.player, true) < self.player:getLostHp() then	--能吃桃吃满血的话就不要用了，不然桃子烂手里
		self.shengguang_used = true
		return true
	end
end

--------------------------------------------------
--圣光（新）
--------------------------------------------------

sgs.ai_skill_invoke.shengguangN = function(self, data)
	local dying = data:toDying()
	local hp = dying.who:getHp()

	return hp > -3 and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + hp < 1
end

--------------------------------------------------
--废宅（新）
--------------------------------------------------

sgs.ai_skill_choice.feizhaiN = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local will_use = false
		local has_equip_area = 0
		for i = 0, 4 do
			if self.player:hasEquipArea(i) then
				has_equip_area = has_equip_area + 1
			end
		end
		if has_equip_area >= 3 and self.player:getHandcardNum() - math.max(getCardsNum("Peach", self.player, self.player, true), self.player:getLostHp()) <= 3 and not self:willSkipPlayPhase() and not self:willSkipDrawPhase() then
			will_use = true
		elseif has_equip_area > 0 and self:isWeak(self.player, true) and not self:willSkipPlayPhase() and not self:willSkipDrawPhase() then
			will_use = true
		end
		if not will_use then
			return "cancel"
		end
		
		if table.contains(items, "jueyan1") and self:needToThrowArmor(self.player, true) then	--需要丢防具就直接废除防具
			return "jueyan1"
		end
		local not_value_location = {4,3,2,1,0}
		for _,card in sgs.qlist(self.player:getCards("he")) do
			if card:isKindOf("EquipCard") and table.contains(not_value_location, card:getRealCard():toEquipCard():location()) then
				table.removeOne(not_value_location, card:getRealCard():toEquipCard():location())
			end
		end
		for _, location in ipairs(not_value_location) do
			if table.contains(items, "jueyan"..location) then	--优先废除不能装备的栏位
				return "jueyan"..location
			end
		end
		if table.contains(items, "jueyan4") then
			return "jueyan4"
		elseif table.contains(items, "jueyan3") then
			return "jueyan3"
		elseif table.contains(items, "jueyan2") then
			return "jueyan2"
		elseif table.contains(items, "jueyan1") then
			return "jueyan1"
		elseif table.contains(items, "jueyan0") then
			return "jueyan0"
		elseif table.contains(items, "cancel") then
			return "cancel"
		end
	end
end



--嘲讽
sgs.ai_chaofeng.youlingzichen_dianziyouling = -2

--------------------------------------------------
--竭心
--------------------------------------------------

sgs.ai_skill_playerchosen.jiexin = function(self, targetlist)
	local target = self:findPlayerToDraw(true, 2)
	targetlist = sgs.QList2Table(targetlist)
	for _, p in ipairs(targetlist) do
		if p:objectName() == target:objectName() then
			return p
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.jiexin = function(self, from, to)
	local intention = -10
	sgs.updateIntention(from, to, intention)
end

sgs.ai_need_damaged.jiexin = function(self, attacker, player)
	if not self:isWeak(player) or self:getAllPeachNum(player) > 0 then
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.xiaoxi_chixingai = 0

--------------------------------------------------
--元初
--------------------------------------------------

sgs.ai_skill_invoke.yuanchu = function(self, data)
	return self.player:getHandcardNum() <= self.player:getMaxCards()-(self.player:aliveCount()/2)
end

--------------------------------------------------
--精算（不会真有人凑32 64吧，不会吧不会吧）
--------------------------------------------------

local jingsuan_skill={}
jingsuan_skill.name="jingsuan"
table.insert(sgs.ai_skills,jingsuan_skill)
jingsuan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@byte") >= 16 then
		return sgs.Card_Parse("#jingsuan:.:")
	end
end
sgs.ai_skill_use_func["#jingsuan"] = function(card, use, self)
	local target = self:findPlayerToDiscard("h", false, true)
	if target and self.player:canEffect(target, "fuguang") then
		if use.to then
			use.to:append(target)
		end
		card_str = "#jingsuan:.:->"..target:objectName()
		use.card = sgs.Card_Parse(card_str)
	end
end

sgs.ai_use_priority["jingsuan"] = 10.1

sgs.ai_card_intention.jingsuan = function(self, card, from, tos)
    local to = tos[1]
	local intention = 10
	if not self:needKongcheng(to) and not to:hasSkills(sgs.lose_card_skills) then
		sgs.updateIntention(from, to, intention)
	end
end




--嘲讽
sgs.ai_chaofeng.xiaotao_tauxingai = 0

--------------------------------------------------
--散热
--------------------------------------------------

sgs.ai_skill_playerchosen.sanre = function(self, targetlist)
	local target = self:findPlayerToDiscard("hej", false, true, targetlist)
	if target then
		targetlist = sgs.QList2Table(targetlist)
		for _, p in ipairs(targetlist) do
			if p:objectName() == target:objectName() then
				return p
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sanre = function(self, from, to)
	local intention = 10
	if not self:needKongcheng(to) and not to:hasSkills(sgs.lose_card_skills) and not to:hasSkills(sgs.need_equip_skill) then
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_choicemade_filter.cardChosen["sanre"] = sgs.ai_choicemade_filter.cardChosen.dismantlement

--------------------------------------------------
--变频
--------------------------------------------------

--sgs.ai_skill_use["@@bianpin"] = function(self, prompt, method)

sgs.ai_skill_invoke.bianpin = function(self, data)
	self:updatePlayers()
	local trigger = false
	if self.player:getChangeSkillState("bianpin") <= 1 then		--变频①
		local use_other_count = 0
		local use_self_count = 0
		local slash_used = false
		local peach_used = 0
		for _, cd in sgs.qlist(self.player:getHandcards()) do
			if cd:isKindOf("TrickCard") and not cd:isKindOf("ExNihilo") then
				if self:willUse(self.player, cd) then
					use_other_count = use_other_count + 1
				end
			elseif cd:isKindOf("Slash") then
				if self:willUse(self.player, cd) and (not slash_used or self:hasCrossbowEffect()) then
					slash_used = true
					use_other_count = use_other_count + 1
				end
			elseif cd:isKindOf("EquipCard") or cd:isKindOf("ExNihilo") or cd:isKindOf("Analeptic") then
				use_self_count = use_self_count + 1
			elseif cd:isKindOf("Peach") and peach_used < self.player:getLostHp() then
				use_self_count = use_self_count + 1
				peach_used = peach_used + 1
			end
			local max_cards = 4
			if (self.player:getHandcardNum() - use_self_count <= max_cards) and use_other_count <= 3 then
				trigger = true
			end
		end
	else											--变频②
		local use_other_count = 0
		local use_self_count = 0
		local slash_used = false
		local peach_used = 0
		for _, cd in sgs.qlist(self.player:getHandcards()) do
			if cd:isKindOf("EquipCard") or cd:isKindOf("ExNihilo") or cd:isKindOf("Analeptic") then
				if self:willUse(self.player, cd) then
					use_self_count = use_self_count + 1
				end
			elseif cd:isKindOf("Peach") and peach_used < self.player:getLostHp() then
				use_self_count = use_self_count + 1
				peach_used = peach_used + 1
			end
			if use_self_count <= 3 then
				trigger = true
			end
		end
	end
	if trigger then
		--return "#bianpin:.:->"..self.player:objectName()
		return true
	end
	return false
end

sgs.ai_skill_discard.bianpin = function(self, discard_num, min_num, optional, include_equip)
	local toDis = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards < 2 then
		return self:askForDiscard("", discard_num, min_num, optional, include_equip)
	end
	local new_aux_func = function(card)		--自定弃牌逻辑（很激进）
		if self:isTemporaryCard(self.player, card:getEffectiveId()) then return -1 end	--临时牌优先扔，仅次于扔狮子
		if card:isKindOf("Analeptic") or card:isKindOf("GodSalvation") or card:isKindOf("AmazingGrace") or card:isKindOf("ExNihilo") then return -0.9 end	--装备牌/酒/五谷/桃园/无中
		if card:isKindOf("Jink") then return -0.5 end	--闪
		if card:isKindOf("Peach") then return 0 end	--桃
		local place = self.room:getCardPlace(card:getEffectiveId())
		if place == sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") and self.player:isWounded() and not self:needToLoseHp(self.player, self.player, false, false, true) then return -2	--弃狮子
			elseif card:isKindOf("OffensiveHorse") then return 3
			elseif card:isKindOf("Weapon") then return 4
			elseif card:isKindOf("DefensiveHorse") then return 1
			elseif card:isKindOf("Armor") or card:isKindOf("Treasure") then return 2
			end
		elseif card:isKindOf("EquipCard") then return -1	--不在装备区的装备牌
		elseif card:isKindOf("Slash") and not self:hasCrossbowEffect() and not self.player:hasSkills(sgs.double_slash_skill) then	--重复的用不了的杀不要
			local slash = self:getCard("FireSlash") or self:getCard("IceSlash") or self:getCard("ThunderSlash") or self:getCard("Slash")	--根据优先级返回一张杀
			if slash and card:getEffectiveId() ~= slash:getEffectiveId() then	--不是最优先的杀就不要
				return -1
			end
		elseif self:getUseValue(card) >= 6 then return 3	--使用价值高的牌，如顺手牵羊(9),下调至桃
		elseif self:hasSkills(sgs.lose_equip_skill) then return 5
		else return 0
		end
		return 0
	end
	
	toDis = dimeng_discard(self, 2, cards, 999, new_aux_func)
	if #toDis == 2 then
		return toDis
	end
	return self:askForDiscard("", discard_num, min_num, optional, include_equip)
end




--嘲讽
sgs.ai_chaofeng.xiaorou_rhoxingai = -1

--------------------------------------------------
--清冷
--------------------------------------------------

sgs.ai_skill_playerchosen.qingleng = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "defense")
	for _, p in ipairs(targetlist) do
		if self:isFriend(p) then
			if p:hasSkills("sanre|yueying|xingyi|guobao") or self:needToThrowArmor() then
				return p
			end
		elseif self:isEnemy(p) and not p:hasSkills(sgs.lose_equip_skill.."|"..sgs.lose_card_skills) then
			return p
		end
	end
	for _, p in ipairs(targetlist) do
		if self:isFriend(p) then
			if not self:isWeak(p) and p:getHandcardNum() >= 3 then
				return p
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.qingleng = function(self, from, to)
	local intention = 0
	sgs.updateIntention(from, to, intention)
end

--[[sgs.ai_skill_cardchosen.qingleng = function(self, who, flags)	--先放弃思考
	if self:isFriend(who) then
		if #self.enemies > 0 then
			if self:needToThrowArmor(who) and who:getArmor() then
				return who:getArmor()
			end
			if who:hasEquip() then
				local equips = sgs.QList2Table(who:getCards("e"))
				self:sortByKeepValue(equips)
				for _, equip in ipairs(equips) do
					return equip
				end
			end
			if not who:isKongcheng() and not hasManjuanEffect(who) then
				return who:getRandomHandCard()
			end
		else
			if not who:isKongcheng() and not hasManjuanEffect(who) then
				return who:getRandomHandCard()
			end
		end
		local cards = who:getCards("he")
		return cards:at(math.random(0, cards:length() - 1))
	end
	
	if #self.friends_noself == 0 then
		if who:hasEquip() then
			local equips = sgs.QList2Table(who:getCards("e"))
			self:sortByKeepValue(equips)
			for _, equip in ipairs(equips) do
				if not (equip:isKindOf("Armor") and self:isEnemy(who) and self:needToThrowArmor(who)) then
					return equip
				end
			end
		end
	else
		if not who:isKongcheng() then
			return who:getRandomHandCard()
		end
	end
	
	local cards = who:getCards("he")
	return cards:at(math.random(0, cards:length() - 1))
end]]

sgs.ai_skill_choice["qingleng"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local from = findPlayerByFlag(self.room, "qingleng_from_AI")
		
		local target_card
		for _, cd in sgs.qlist(self.player:getHandcards()) do
			if cd:hasFlag("qingleng") then
				target_card = cd
				break
			end
		end
		
		if table.contains(items, "qingleng_destroy") then
			if from and self:isFriend(from) then
				if not (target_card and (target_card:isKindOf("ExNihilo") or (target_card:isKindOf("Peach") and self:isWeak()) or target_card:isKindOf("SilverLion"))) then
					return "qingleng_destroy"
				end
			elseif self.player:hasSkills("sanre") then
				return "qingleng_destroy"
			end
		end
		if table.contains(items, "qingleng_get") then
			return "qingleng_get"
		end
		if table.contains(items, "qingleng_use") then
			self:updatePlayers()
			self:sort(self.enemies, "defense")
			if target_card then
				if target_card:targetFixed() then
					--if target_card:isKindOf("EquipCard") then
					--	local equip_index = target_card:getRealCard():toEquipCard():location()
					--	if self.player:getEquip(equip_index) == nil and self.player:hasEquipArea(equip_index) then
					--		return "qingleng_use"
					--	end
					--end
					if target_card:isKindOf("EquipCard") and self:willUse(self.player, target_card) then
						return "qingleng_use"
					end
					if target_card:isKindOf("Armor") then
						local equip_index = target_card:getRealCard():toEquipCard():location()
						if self.player:getEquip(equip_index) ~= nil and self.player:hasEquipArea(equip_index) and self:needToThrowArmor() then
							return "qingleng_use"
						end
					end
					if target_card:isKindOf("SavageAssault") then
						local savage_assault = sgs.Sanguosha:cloneCard("SavageAssault")
						if self:getAoeValue(savage_assault) > 0 then
							savage_assault:deleteLater()
							return "qingleng_use"
						end
						savage_assault:deleteLater()
					end
					if target_card:isKindOf("ArcheryAttack") then
						local archery_attack = sgs.Sanguosha:cloneCard("ArcheryAttack")
						if self:getAoeValue(archery_attack) > 0 then
							archery_attack:deleteLater()
							return "qingleng_use"
						end
						archery_attack:deleteLater()
					end
					if target_card:isKindOf("Peach") and self.player:isWounded() then
						return "qingleng_use"
					end
					if target_card:isKindOf("ExNihilo") then
						return "qingleng_use"
					end
				elseif target_card:isKindOf("TrickCard") then
					local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
					self:useTrickCard(target_card, dummyuse)
					if not dummyuse.to:isEmpty() then
						return "qingleng_use"
					end
				elseif target_card:isKindOf("Slash") then
					local slash = target_card
					for _,enemy in ipairs(self.enemies) do	--yun
						if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) and self.player:canSlash(enemy, slash, true) then
							return "qingleng_use"
						end
					end
				end
				if (self:needKongcheng() and self.player:getHandcardNum() == 1) or hasManjuanEffect(self.player) then
					return "qingleng_use"
				end
			end
		end
	end
	return "qingleng_destroy"
end

sgs.ai_skill_use["@@qingleng!"] = function(self, prompt, method)
	self:updatePlayers()
	
	local target_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:hasFlag("qingleng") then
			table.insert(target_cards, cd)
		end
	end
	if #target_cards == 0 then return end
	
	self:sortByUseValue(target_cards, true)
	target_cards = sgs.reverse(target_cards)
	
	for _,target_card in ipairs(target_cards) do
		if target_card:targetFixed() then
			return target_card:toString()
		else
			if target_card:isKindOf("Slash") then	--yun
				local to = self:findPlayerToSlash(true, target_card, nil, true)		--距离限制、卡牌、角色限制、必须选择
				return target_card:toString() .. "->" .. to:objectName()
			end
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(target_card, dummyuse)
			local targets = {}
			if not dummyuse.to:isEmpty() then
				for _, p in sgs.qlist(dummyuse.to) do
					table.insert(targets, p:objectName())
				end
				return target_card:toString() .. "->" .. table.concat(targets, "+")
			else		--强制选择随机目标
				local targets_list = sgs.PlayerList()
				for _, target in sgs.qlist(self.room:getAlivePlayers()) do
					targets_list:append(target)
				end
				local targets = {}
				for _,p in sgs.qlist(self.room:getAlivePlayers()) do
					if target_card:targetFilter(targets_list, p, self.player) and not sgs.Self:isProhibited(p, target_card) then
						table.insert(targets, p:objectName())
					end
				end
				if #targets > 0 then
					return target_card:toString() .. "->" .. targets[math.random(1,#targets)]
				end
			end
		end
	end
	return "."
end

--------------------------------------------------
--情柔
--------------------------------------------------

sgs.ai_skill_invoke.qingrou = function(self, data)
	local target = data:toPlayer()
	if not target then return false end
	if self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@qingrou_give"] = function(self, data, pattern, target)
	if self:needToThrowArmor() and self.player:getArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards, self:isFriend(self.room:getCurrent()))
	for _, card in ipairs(cards) do
		return "$" .. card:getEffectiveId()
	end
	return "$" .. cards[1]:getEffectiveId()
end




--嘲讽
sgs.ai_chaofeng.lanyin_yuezhigongzhutu = 0

--------------------------------------------------
--云谣
--------------------------------------------------

sgs.ai_view_as.yunyao = function(card, player, card_place)
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or card_place == sgs.Player_PlaceEquip or (card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "wooden_ox") then
		if player:getMark("@yunyueyao_using_black") + player:getMark("@yunyueyao_using_red") == 0 and not card:isKindOf("BasicCard") then
			return ("nullification:yunyao[%s:%s]=%d"):format("to_be_decided", 0, card_id)
		end
	end
end

sgs.ai_cardneed.yunyao = function(to, card, self)
	return not card:isKindOf("BasicCard")
end

--------------------------------------------------
--国宝
--------------------------------------------------

sgs.ai_skill_playerchosen.guobao = function(self, targetlist)
	self:sort(self.friends, "defense")
	local target = self.friends[1]
	if target then
		targetlist = sgs.QList2Table(targetlist)
		for _, p in ipairs(targetlist) do
			if p:objectName() == target:objectName() then
				return p
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.guobao = function(self, from, to)
	local intention = -10
	sgs.updateIntention(from, to, intention)
end




--嘲讽
sgs.ai_chaofeng.toufa_shiyixian = 0

--------------------------------------------------
--流易
--------------------------------------------------

sgs.ai_skill_invoke.liuyi = function(self, data)
	local data = self.player:getTag("liuyi")
	local judge = data:toJudge()
	if self:needRetrial(judge) then
		return true
	elseif self:isFriend(judge.who) then
		if not judge:isGood() then
			return true
		else
			return false
		end
	elseif self:isEnemy(judge.who) then
		if judge:isGood() then
			return true
		else
			return false
		end
	end
	return false
end

--------------------------------------------------
--诲谕
--------------------------------------------------

sgs.ai_skill_invoke.huiyu = function(self, data)
	local target = data:toPlayer()
	if not target then return false end
	if target:objectName() == self.player:objectName() then
		return true
	elseif self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_skill_askforag.huiyu = function(self, card_ids)
	local cards = {}
	for _, id in ipairs(card_ids) do
		if sgs.Sanguosha:getCard(id):isBlack() then
			return id
		end
	end
	for _, id in ipairs(card_ids) do
		return id
	end
	return -1
end




--嘲讽
sgs.ai_chaofeng.bijujieyi_senluozhilantu = 1

--------------------------------------------------
--病娇
--------------------------------------------------

sgs.ai_skill_cardask["@bingjiao_give"] = function(self, data, pattern, target)
	local current = self.room:getCurrent()
	if self:isEnemy(current) and (self:isWeak(current) or self:getOverflow(current) > 0) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValue(cards, self:isFriend(current))
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Heart then
				return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end

sgs.ai_skill_choice.bingjiao = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if self.player:getHp() + self:getAllPeachNum(self.player) - 1 <= 0 then
			return "bingjiao_skip"
		elseif self:getOverflow() >= 2 then
			return "bingjiao_damage"
		end
		return "bingjiao_skip"
	end
end

sgs.ai_cardneed.bingjiao = function(to, card, self)
	return card:getSuit() == sgs.Card_Heart
end

sgs.bingjiao_suit_value = {
	heart = 6,
}




--嘲讽
sgs.ai_chaofeng.chushuang_jinglingxuediao = 2

--嘲讽
sgs.ai_chaofeng.xiyue_shenshengxuantu = 0

--------------------------------------------------
--月引
--------------------------------------------------

local yueyinvs_skill = {}
yueyinvs_skill.name = "yueyinvs"
table.insert(sgs.ai_skills,yueyinvs_skill)
yueyinvs_skill.getTurnUseCard=function(self)
	if self:needBear() then return end
	if not self.player:isKongcheng() and self.player:getHandcardNum() > self.player:getHp() then
		return sgs.Card_Parse("#yueyinvs:.:")
	end
end

sgs.ai_skill_use_func["#yueyinvs"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, false)
	for _, p in sgs.qlist(self.room:findPlayersBySkillName("yueyin")) do
		if self:isFriend(p) and p:objectName() ~= self.player:objectName() and p:getMark("yueyin_used") == 0 and (self:getOverflow() > 0 or p:getHandcardNum() < p:getHp()) then
			for _,give_card in ipairs(handcards) do
				if self:willUse(p, give_card) then
					use.card = sgs.Card_Parse("#yueyinvs:" .. give_card:getId() .. ":->" .. p:objectName())
					if use.to then
						use.to:append(p)
					end
					return
				end
			end
		end
	end
end

sgs.ai_use_value.yueyinvs = 2.5
sgs.ai_use_priority.yueyinvs = 9
sgs.ai_card_intention.yueyinvs = -10

--------------------------------------------------
--星移
--------------------------------------------------

sgs.ai_skill_choice["xingyi"] = function(self, choices, data)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	
	local target_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:hasFlag("xingyi") then
			table.insert(target_cards, cd)
		end
	end
	if #target_cards == 0 then
		if not self:canDraw(self.player) or (self.player:getHandcardNum() == self.player:getHp() and self.player:hasFlag("yueyin_first_move")) then
			return "xingyi_discard"
		end
	end
	
	self:sortByUseValue(target_cards, true)
	target_cards = sgs.reverse(target_cards)
	
	for _,target_card in ipairs(target_cards) do
		if target_card:targetFixed() then
			if self.player:hasFlag("yueyin_first_move") then	--若有月引则尽量用装备牌，否则按照普通判定使用
				if target_card:isKindOf("EquipCard") then
					local equip_index = target_card:getRealCard():toEquipCard():location()
					if (self.player:getEquip(equip_index) == nil or self.player:getHandcardNum() > self:getBestKeepHandcardNum()) and self.player:hasEquipArea(equip_index) then
						return "xingyi_use"
					end
				end
			else
				if target_card:isKindOf("EquipCard") and self:willUse(self.player, target_card) then
					return "xingyi_use"
				end
			end
			if target_card:isKindOf("Armor") then
				local equip_index = target_card:getRealCard():toEquipCard():location()
				if self.player:getEquip(equip_index) ~= nil and self.player:hasEquipArea(equip_index) and self:needToThrowArmor() then
					return "xingyi_use"
				end
			end
			if target_card:isKindOf("SavageAssault") then
				local savage_assault = sgs.Sanguosha:cloneCard("SavageAssault")
				if self:getAoeValue(savage_assault) > 0 then
					savage_assault:deleteLater()
					return "xingyi_use"
				end
				savage_assault:deleteLater()
			end
			if target_card:isKindOf("ArcheryAttack") then
				local archery_attack = sgs.Sanguosha:cloneCard("ArcheryAttack")
				if self:getAoeValue(archery_attack) > 0 then
					archery_attack:deleteLater()
					return "xingyi_use"
				end
				archery_attack:deleteLater()
			end
			if target_card:isKindOf("Peach") and self.player:getLostHp() > 0 then
				return "xingyi_use"
			end
			if target_card:isKindOf("ExNihilo") then
				return "xingyi_use"
			end
		elseif target_card:isKindOf("TrickCard") then
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(target_card, dummyuse)
			if not dummyuse.to:isEmpty() then
				return "xingyi_use"
			end
		elseif target_card:isKindOf("Slash") then
			local slash = target_card
			for _,enemy in ipairs(self.enemies) do	--yun
				if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) and self.player:canSlash(enemy, slash, true) then
					return "xingyi_use"
				end
			end
		end
		if not self:canDraw(self.player) then
			return "xingyi_use"
		end
	end
	return "cancel"
end

sgs.ai_skill_use["@@xingyi!"] = function(self, prompt, method)
	self:updatePlayers()
	
	local target_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:hasFlag("xingyi") then
			table.insert(target_cards, cd)
		end
	end
	if #target_cards == 0 then return end
	
	self:sortByUseValue(target_cards, true)
	target_cards = sgs.reverse(target_cards)
	
	for _,target_card in ipairs(target_cards) do
		if target_card:targetFixed() then
			return target_card:toString()
		else
			if target_card:isKindOf("Slash") then	--yun
				local to = self:findPlayerToSlash(true, target_card, nil, true)		--距离限制、卡牌、角色限制、必须选择
				return target_card:toString() .. "->" .. to:objectName()
			end
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(target_card, dummyuse)
			local targets = {}
			if not dummyuse.to:isEmpty() then
				for _, p in sgs.qlist(dummyuse.to) do
					table.insert(targets, p:objectName())
				end
				return target_card:toString() .. "->" .. table.concat(targets, "+")
			else		--强制选择随机目标
				local targets_list = sgs.PlayerList()
				for _, target in sgs.qlist(self.room:getAlivePlayers()) do
					targets_list:append(target)
				end
				local targets = {}
				for _,p in sgs.qlist(self.room:getAlivePlayers()) do
					if target_card:targetFilter(targets_list, p, self.player) and not sgs.Self:isProhibited(p, target_card) then
						table.insert(targets, p:objectName())
					end
				end
				if #targets > 0 then
					return target_card:toString() .. "->" .. targets[math.random(1,#targets)]
				end
			end
		end
	end
	return "."
end




--嘲讽
sgs.ai_chaofeng.pengshanmu_zhuoluofengchan = 0

--------------------------------------------------
--郁生
--------------------------------------------------

sgs.ai_skill_invoke.yusheng = function(self, data)
	return true
end

sgs.ai_skill_choice.yusheng = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if table.contains(items, "yusheng_keep") and (self.player:getMark("&yusheng!") == 0 or (self:isWeak() and self:getCardsNum("Jink") + self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0)) then
			return "yusheng_keep"
		end
		return "yusheng_draw"
	end
end




--嘲讽
sgs.ai_chaofeng.xiaheyi_yinyangshi = 1

--------------------------------------------------
--结印
--------------------------------------------------

local jieyin_v_skill={}
jieyin_v_skill.name="jieyin_v"
table.insert(sgs.ai_skills,jieyin_v_skill)
jieyin_v_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local card
	self:sortByUseValue(cards, true)

	local slash = self:getCard("IceSlash") or self:getCard("FireSlash") or self:getCard("ThunderSlash") or self:getCard("Slash")
	if slash then
		local dummy_use = { isDummy = true }
		self:useBasicCard(slash, dummy_use)
		if not dummy_use.card then slash = nil end
	end

	for _, acard in ipairs(cards) do
		if acard:getSuit() == sgs.Card_Spade then
			local shouldUse = true
			if self:getUseValue(acard) > sgs.ai_use_value.IronChain and acard:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(acard, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if acard:getTypeId() == sgs.Card_TypeEquip then
				local dummy_use = { isDummy = true }
				self:useEquipCard(acard, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse and (not slash or slash:getEffectiveId() ~= acard:getEffectiveId()) then
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("iron_chain:jieyin_v[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_cardneed.jieyin_v = function(to, card)
	return card:getSuit() == sgs.Card_Spade and to:getHandcardNum() <= 2
end

--------------------------------------------------
--禁咒
--------------------------------------------------

local jinzhou_skill={}
jinzhou_skill.name="jinzhou"
table.insert(sgs.ai_skills,jinzhou_skill)
jinzhou_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#jinzhou") < 1 and not self.player:isNude() then
		return sgs.Card_Parse("#jinzhou:.:")
	end
end
sgs.ai_skill_use_func["#jinzhou"] = function(card, use, self)
	local cards = {}
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if card:isBlack() then
			table.insert(cards, card)
		end
	end
	if #cards == 0 then return end
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if not (self:needToLoseHp(enemy) or enemy:hasSkills(sgs.lose_hp_skills)) and #cards >= math.max(enemy:getLostHp(), 1) and SkillCanTarget(enemy, self.player, "jinzhou") and self.player:canEffect(enemy, "jinzhou") and (self:isWeak(enemy) or self:getOverflow()+1 >= math.max(enemy:getLostHp(), 1)) then
			local ids = dimeng_discard(self, math.max(enemy:getLostHp(), 1), cards)
			if use.to then
				use.to:append(enemy)
			end
			card_str = "#jinzhou:"..table.concat(ids, "+")..":->"..enemy:objectName()
			use.card = sgs.Card_Parse(card_str)
			break
		end 
	end
end

sgs.ai_use_priority["jinzhou"] = 8

sgs.ai_card_intention.jinzhou = function(self, card, from, tos)
    local to = tos[1]
    local intention = 10
    if self:needToLoseHp(to) or to:hasSkills(sgs.lose_hp_skills) then
        intention = -10
    end
    sgs.updateIntention(from, to, intention)
end

sgs.ai_cardneed.jinzhou = function(to, card, self)
	return card:isBlack()
end

--------------------------------------------------
--鹤唳
--------------------------------------------------

sgs.ai_skill_invoke.heli = function(self, data)
	return true		--就烧，魂就完事了
end

sgs.ai_skill_cardask["@heli_give"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards, self:isFriend(self.room:getCurrent()))
	for _, card in ipairs(cards) do
		if card:isBlack() then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end




--嘲讽
sgs.ai_chaofeng.ailulu_hunaoxiaoxiongmao = 2

--------------------------------------------------
--藏宝
--------------------------------------------------

local cangbao_skill = {}
cangbao_skill.name = "cangbao"
table.insert(sgs.ai_skills, cangbao_skill)
cangbao_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#cangbao") >= 1 then return end
	return sgs.Card_Parse("#cangbao:.:")
end
sgs.ai_skill_use_func["#cangbao"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	
	local targets = sgs.SPlayerList()
	for _, vic in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not vic:isNude() and (vic:getHandcardNum() > self.player:getHandcardNum() or (vic:getHandcardNum() == self.player:getHandcardNum() and #handcards > 0)) and SkillCanTarget(vic, self.player, "cangbao") and self.player:canEffect(vic, "cangbao") then
			targets:append(vic)
		end
	end
	
	local to_discard = {}
	if not targets:isEmpty() then
		--self:sort(targets, "defense")
		local target = self:findPlayerToDiscard("he", false, false, targets, false)
		if target then
			if target:getHandcardNum() == self.player:getHandcardNum() then		--双方手牌数相同只能弃手牌
				to_discard = dimeng_discard(self, 1, handcards)
			else
				to_discard = dimeng_discard(self, 1, cards)
			end
			if #to_discard > 0 then
				if use.to then
					use.to:append(target)
				end
				card_str = "#cangbao:"..to_discard[1]..":->"..target:objectName()
				use.card = sgs.Card_Parse(card_str)
			end
		end
	end
end

sgs.ai_use_value["cangbao"] = 1 --卡牌使用价值
sgs.ai_use_priority["cangbao"] = sgs.ai_use_priority.Slash + 0.2 --卡牌使用优先级

sgs.ai_choicemade_filter.cardChosen["cangbao"] = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_card_intention.cangbao = function(self, card, from, tos)
    local to = tos[1]
    local intention = 10
    if self:needKongcheng(to) then
        intention = 0
    end
    sgs.updateIntention(from, to, intention)
end




--嘲讽
sgs.ai_chaofeng.youyueying_fuyunzuofutong = 1

--------------------------------------------------
--福佑
--------------------------------------------------

sgs.ai_skill_invoke["fuyou"] = function(self, data)	--yun
	local current_dying_player = data:toPlayer()
	if current_dying_player and self:canDraw(current_dying_player) then
		if self:isFriend(current_dying_player) then
			sgs.updateIntention(self.player, current_dying_player, -10)
			return true
		else
			sgs.updateIntention(self.player, current_dying_player, 10)
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.fuyou = function(self, player, promptlist)	--yun
	local dying = findPlayerByFlag(self.room, "fuyou_dying_AI")
	if dying and self:canDraw(dying, player) then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, dying, -10) 
		elseif promptlist[#promptlist] == "no" then
			sgs.updateIntention(player, dying, 10)
		end
	end
end

--------------------------------------------------
--满愿
--------------------------------------------------

local manyuan_skill = {}
manyuan_skill.name = "manyuan"
table.insert(sgs.ai_skills, manyuan_skill)
manyuan_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#manyuan") >= 1 or self.player:isKongcheng() then return end
	return sgs.Card_Parse("#manyuan:.:")
end
sgs.ai_skill_use_func["#manyuan"] = function(card, use, self)
	local N = self.player:getHandcardNum()
	local friends = sgs.SPlayerList()
	local target
	for _, vic in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if N == 1 and self:isEnemy(vic) and (((self:isWeak(vic) or self:willSkipPlayPhase(vic)) and vic:getMaxCards() > 0 and vic:getMaxCards() <= 2) or (self:needKongcheng(vic) and vic:isKongcheng())) and self.player:canEffect(vic, "manyuan") then
			target = vic
			break
		end
		if self:isFriend(vic) and not (self:needKongcheng(vic) and vic:isKongcheng()) and not hasManjuanEffect(vic) and self.player:canEffect(vic, "manyuan") then
			friends:append(vic)
		end
	end
	if target then
		if use.to then
			use.to:append(target)
		end
		card_str = "#manyuan:.:->"..target:objectName()
		use.card = sgs.Card_Parse(card_str)
	elseif not friends:isEmpty() then
		friends = sgs.QList2Table(friends)
		local target = self:findPlayerToDraw2(false, N, friends, true, true, false)
		if target then
			if use.to then
				use.to:append(target)
			end
			card_str = "#manyuan:.:->"..target:objectName()
			use.card = sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_value["manyuan"] = 1 --卡牌使用价值
sgs.ai_use_priority["manyuan"] = 1.29 --卡牌使用优先级

sgs.ai_card_intention.manyuan = function(self, card, from, tos)
    local to = tos[1]
    local intention = -10
    if from:getHandcardNum() == 1 or hasManjuanEffect(to) or (self:needKongcheng(to) and to:isKongcheng()) or self:willSkipPlayPhase(to) then
        intention = 0
    end
    sgs.updateIntention(from, to, intention)
end

sgs.ai_need_damaged.manyuan = function (self, attacker, player)
	if player:getHp() == 1 and player:getMaxHp() - player:getHp() + 1 >= 2 and self:getAllPeachNum(player) > 0 then
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.beishanghuahuo_xuanlancuantianhou = 0

--------------------------------------------------
--自荐
--------------------------------------------------

sgs.ai_skill_playerchosen.zijian = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	local N = self.player:getMark("zijian_AI")
	local target = self:findPlayerToDraw2(false, N, targetlist, false, true, false)
	if target then
		return target
	end
end

sgs.ai_playerchosen_intention.zijian = function(self, from, to)
    local intention = -10
    if hasManjuanEffect(to) or (self:needKongcheng(to) and to:isKongcheng()) or self:willSkipPlayPhase(to) then
        intention = 0
    end
    sgs.updateIntention(from, to, intention)
end

--------------------------------------------------
--惊心
--------------------------------------------------

sgs.ai_skill_invoke.jingxin = function(self, data)
	local objname = string.sub(data:toString(), 8, -1)	--截取choice:后面的部分(即player:objectName())
	local from = findPlayerByFlag(self.room, "jingxin_usefrom_AI")
	if from and not self:isFriend(from) and self.player:getHp() >= 3 then	--状态好无脑发动，卖状态换牌
		return true
	end
	if (self.player:hasArmorEffect("vine") and (objname == "slash" or objname == "savage_assault" or objname == "archery_attack")) or (self.player:hasArmorEffect("renwang_shield") and (objname == "slash" or objname == "fire_slash" or objname == "thunder_slash")) then
		return not self:isWeak()
	end
	if (objname == "fire_slash" or objname == "thunder_slash" or objname == "fire_attack") and from and self:isFriend(from) then
		return false
	end
	if (objname == "fire_slash" or objname == "thunder_slash" or objname == "slash" or objname == "archery_attack") then	--需要出闪
		return self:getCardsNum("Jink") == 0 and not (objname == "archery_attack" and self:getCardsNum("Nullification") == 0)
	end
	if (objname == "duel" or objname == "savage_assault") then	--需要出杀
		return self:getCardsNum("Slash")+self:getCardsNum("Nullification") == 0
	end
	if (objname == "snatch" or (objname == "fire_attack" and self:isWeak())) then	--需要无懈
		return self:getCardsNum("Nullification") == 0
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.leidi_haizaomao = 1

--------------------------------------------------
--沐光
--------------------------------------------------
--[[
sgs.ai_skill_invoke["muguang"] = function(self, data)	--yun
	local target = data:toPlayer()
	if target and self:canDraw(target) then
		if self:isFriend(target) then
			sgs.updateIntention(self.player, target, -10)
			return true
		else
			sgs.updateIntention(self.player, target, 10)
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.muguang = function(self, player, promptlist)	--yun
	local target = self.room:getCurrent()
	if target and self:canDraw(target, player) then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, target, -10) 
		elseif promptlist[#promptlist] == "no" then
			sgs.updateIntention(player, target, 10)
		end
	end
end]]

sgs.ai_skill_cardask["@muguang_give"] = function(self, data, pattern, target)
	local to = data:toPlayer()
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(cards, false)
	if self:getOverflow() > 0 or not self:isWeak() then		--自己不濒死或溢出就给最不需要的手牌
		for _, card in ipairs(cards) do
			if (self:canDraw(to) and self:isFriend(to)) or (not self:canDraw(to) and self:isEnemy(to)) then
				return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end

sgs.ai_cardneed.muguang = function(to, card, self)	--需要自己留桃
	return card:isKindOf("Peach")
end

--------------------------------------------------
--摸鱼
--------------------------------------------------

local moyu_skill={}
moyu_skill.name="moyu"
table.insert(sgs.ai_skills,moyu_skill)
moyu_skill.getTurnUseCard=function(self,inclusive)
	if self.player:usedTimes("#moyu") < 1 and not self.player:isKongcheng() then
		local use_moyu = false
		
		local average_use_value = 0
		for _, cd in sgs.qlist(self.player:getHandcards()) do
			average_use_value = average_use_value + self:getUseValue(cd)
		end
		average_use_value = average_use_value / self.player:getHandcardNum()
		
		if average_use_value < 6 and (self.player:getHandcardNum() <= 2 or self:getOverflow() <= 0) then
			return sgs.Card_Parse("#moyu:.:")
		end
	end
end

sgs.ai_skill_use_func["#moyu"] = function(card,use,self)
	if not use.isDummy then self:speak("moyu") end
	use.card = card
end

sgs.ai_use_priority["moyu"] = 0





--嘲讽
sgs.ai_chaofeng.xuehusang_zizaisuixin = 1

--------------------------------------------------
--狐言
--------------------------------------------------

local huyan_skill={}
huyan_skill.name="huyan"
table.insert(sgs.ai_skills,huyan_skill)
huyan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#huyan") < 1 and not self.player:isKongcheng() and not self:needBear(self.player, false, nil, "xindong") and self:needToThrowHandcard(self.player, 1) then
		return sgs.Card_Parse("#huyan:.:")
	end
end
sgs.ai_skill_use_func["#huyan"] = function(card, use, self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	
	local targetlist = self.room:getOtherPlayers(self.player)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "defense")
	
	for _, card in ipairs(cards) do
		local class_name = card:getClassName()
		if class_name == "FireSlash" or class_name == "ThunderSlash" then
			class_name = "Slash"
		end
		for _, vic in ipairs(targetlist) do
			if SkillCanTarget(vic, self.player, "huyan") and not vic:isKongcheng() and getCardsNum(class_name, vic, self.player, true) > 0 then
				if (self:isFriend(vic) and self:needToThrowHandcard(vic, 1, sgs.CardMoveReason_S_REASON_EXTRACTION)) or (self:isEnemy(vic) and not self:needToThrowHandcard(vic, 1, sgs.CardMoveReason_S_REASON_EXTRACTION)) then
					if use.to then
						use.to:append(vic)
					end
					card_str = "#huyan:"..card:getId()..":->"..vic:objectName()
					use.card = sgs.Card_Parse(card_str)
					return
				end
			end
		end
	end
	
	for _, card in ipairs(cards) do
		local class_name = card:getClassName()
		if class_name == "FireSlash" or class_name == "ThunderSlash" then
			class_name = "Slash"
		end
		if class_name == "Jink" and not self:isWeak() then
			for _, vic in ipairs(targetlist) do
				if SkillCanTarget(vic, self.player, "huyan") and not vic:isKongcheng() and self:isEnemy(vic) and self:isWeak(vic) and (vic:getHandcardNum() - getCardsNum("VisibleCard", vic, self.player)) > 0 then
					if use.to then
						use.to:append(vic)
					end
					card_str = "#huyan:"..card:getId()..":->"..vic:objectName()
					use.card = sgs.Card_Parse(card_str)
					return
				end
			end
		end
	end
	
	if self:needToThrowHandcard(self.player, 1) then
		for _, vic in ipairs(targetlist) do
			if (self:isFriend(vic) and self:needToThrowHandcard(vic, 1, sgs.CardMoveReason_S_REASON_EXTRACTION)) or (self:isEnemy(vic) and not self:needToThrowHandcard(vic, 1, sgs.CardMoveReason_S_REASON_EXTRACTION)) then
				local cards = self.player:getCards("h")
				cards = sgs.QList2Table(cards)
				local ids = dimeng_discard(self, 1, cards)
				if use.to then
					use.to:append(vic)
				end
				card_str = "#huyan:"..ids[1]..":->"..vic:objectName()
				use.card = sgs.Card_Parse(card_str)
				return
			end
		end
	end
end

sgs.ai_use_priority["huyan"] = sgs.ai_use_priority.Slash + 0.2

sgs.ai_card_intention.huyan = function(self, card, from, tos)
	if #tos > 0 then
		for _,to in ipairs(tos) do
			if not self:needToThrowHandcard(to, 1, sgs.CardMoveReason_S_REASON_EXTRACTION) then
				sgs.updateIntention(from, to, 10)
			end
		end
	end
	return 0
end

--------------------------------------------------
--心动
--------------------------------------------------

sgs.ai_skill_use["@@xindong"] = function(self, prompt, method)
	local targets = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:isFemale() and SkillCanTarget(p, self.player, "xindong") then
			table.insert(targets, p)
		end
	end
	local target = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, targets, false, 0, false)
	if target then
		return "#xindong:.:->"..target:objectName()
	end
end

sgs.ai_playerchosen_intention.xindong = function(self, from, to)
	local intention = 50
	if self:isFriend(from, to) and table.contains(self:findPlayerToDamage(1, from, sgs.DamageStruct_Normal, {to}, false, 0, true), to) then
		intention = 0
	elseif self:needToLoseHp(to) or to:hasSkills(sgs.masochism_skill) then
		intention = 0
	end
	sgs.updateIntention(from, to, intention)
end

--------------------------------------------------
--心动（新）
--------------------------------------------------

--[[sgs.ai_skill_invoke.newxindong = function(self, data)
	local data_str = data:toString()
	if string.startsWith(data_str, "not_give") then		--不需要给
		return true
	elseif string.startsWith(data_str, "need_give") then
		local change_state = self.player:getChangeSkillState("newxindong")
		if change_state ~= 2 then
			change_state = 1
		end
		
		if self.player:isKongcheng() and change_state == 2 then		--心动②，摸1后给不了2
			return true
		end
		local to_str = data_str:split(":"):at(1)
		if not to_str or to_str == "" then
			return true
		else
			local to = findPlayerByObjName(self.room, to_str)
			if not to or not to:isAlive() then	--目标不存在或已死亡
				return true
			else
				if self:isFriend(to) then		--是友方
					return true
				elseif self:isEnemy(to) then	--是敌方
					--待完成
				else							--敌友未知
					if change_state == 2 then
						return true
					elseif self.player:getHandcardNum() >= 3 then
						return true
					end
				end
			end
		end
	end
	return false
end]]

--sgs.ai_skill_invoke.newxindong = sgs.ai_skill_invoke.wangxi		--有什么问题吗（狗头）您好有的

sgs.ai_skill_invoke.newxindong = function(self, data)
	local data_str = data:toString()
	if string.startsWith(data_str, "change") then
		local change_state = 1
		if string.startsWith(data_str, "change2") then
			change_state = 2
		end
		
		local to_str = data_str:split(":")[2]	--获取目标
		if not to_str or to_str == "" then
			return false
		end
		local to = findPlayerByObjName(self.room, to_str)
		if not to or not to:isAlive() then
			return false
		end
		
		if self:isFriend(to) then		--是友方
			return self:canDraw(to)
		elseif self:isEnemy(to) then	--是敌方
			if not self:canDraw(to) then
				return true
			end
			if self.player:getPhase() == sgs.Player_NotActive and not self:hasCrossbowEffect(to) and not to:hasSkills(sgs.Active_cardneed_skill) then
				if change_state == 1 then
					return true
				elseif self:isWeak() and self:getAllPeachNum(player) == 0 then
					return true
				end
			elseif self.player:getPhase() == sgs.Player_Play and not to:hasSkills(sgs.notActive_cardneed_skill) then
				return true
			end
		else							--敌友未知
			if change_state == 1 or self.player:getPhase() == sgs.Player_Play or self:isWeak() then
				return true
			end
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.newxindong = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	local target = nil
	if damage.from and damage.from:objectName() == player:objectName() then
		target = damage.to
	elseif damage.to and damage.to:objectName() == player:objectName() then
		target = damage.from
	end
	if target and promptlist[3] == "yes" then
		if self:needKongcheng(target, true) then sgs.updateIntention(player, target, 10)
		elseif not hasManjuanEffect(target) and ((player:getChangeSkillState("newxindong") == 2 and not self:isWeak(player)) or self:isFriend(player, target)) then sgs.updateIntention(player, target, -10)
		end
	end
end

sgs.ai_need_damaged.newxindong = function(self, attacker, player)
	if attacker and self:isFriend(attacker) and (not self:isWeak(player) or self:getAllPeachNum(player) > 0) then
		return true
	end
	return false
end

sgs.ai_need_damage.newxindong = function(self, player, to)		--新增 need_damage 表示需要造成伤害
	if to and self:isFriend(to) and (not self:isWeak(to) or self:getAllPeachNum(player) > 0) then
		return true
	end
	return false
end

sgs.ai_skill_discard.newxindong = function(self, discard_num, min_num, optional, include_equip)
	local toDis = {}
	local target = findPlayerByFlag(self.room, "newxindong_receiver_AI")
	if target and self:isFriend(target) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(cards, false)
		for _, card in ipairs(cards) do
			if self:needCard(target, card) then		--新函数，返回某角色是否需要某张牌（根据cardneed）
				table.insert(toDis, card:getEffectiveId())
				return toDis
			end
		end
		table.insert(toDis, cards[1]:getEffectiveId())
		return toDis
	end
	return self:askForDiscard("", discard_num, min_num, optional, include_equip)
end




--嘲讽
sgs.ai_chaofeng.youzi_yuko = 2

--------------------------------------------------
--渊回
--------------------------------------------------

sgs.ai_skill_playerchosen.yuanhui = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "handcard")
	
	return self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, targetlist, false, 0, false)
end

--造成伤害自带仇恨值，不用写

sgs.ai_cardneed.yuanhui = function(to, card, self)	--需要黑杀
	return (card:isKindOf("Slash") and card:isBlack())
end

--------------------------------------------------
--终语
--------------------------------------------------

sgs.ai_skill_use["@@zhongyu"] = function(self, prompt)
	local targets = {}
	local players = sgs.SPlayerList()
	for _, vic in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if SkillCanTarget(vic, self.player, "zhongyu") and self.player:canEffect(vic, "zhongyu") then
			players:append(vic)
		end
	end
	if not players:isEmpty() then
		players = sgs.QList2Table(players)
		self:sort(players, "hp")
		
		for _, to in ipairs(players) do
			if #targets >= self.player:getMark("zhongyu_X") then
				break
			end
			if self:isEnemy(to) and not self:needToLoseHp(to) and not to:hasSkills(sgs.lose_hp_skills) then
				table.insert(targets, to:objectName())
			elseif self:isFriend(to) and (self:needToLoseHp(to) or (to:hasSkills(sgs.lose_hp_skills) and not self:isWeak(to))) then
				table.insert(targets, to:objectName())
			end
		end
	end
	return "#zhongyu:.:->"..table.concat(targets, "+")
end

sgs.ai_need_damage.zhongyu = function(self, player, to)		--新增 need_damage 表示需要造成伤害
	if player:getMark("zhongyu_damage_counter") < 6 then	--要启动啊！
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.mutangchun_recorder = 0

--------------------------------------------------
--纪实
--------------------------------------------------

sgs.ai_skill_askforag["jishi_M"] = function(self, card_ids)
	if self:canDraw(self.player) then
		return self:askForAG(card_ids, false, "default")
	else
		return nil
	end
end

--------------------------------------------------
--同我
--------------------------------------------------

sgs.ai_skill_invoke.tongwo = function(self, data)
	if self:isWeak(self.player, true) then
		return true
	else
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if self:isWeak(enemy) and self.player:canSlash(enemy) and (self:getCardsNum("Slash") > 0 or enemy:getHp() == 1) then
				has_weak_enemy = true
			end
		end
		return has_weak_enemy
	end
end

--------------------------------------------------
--同我（新）
--------------------------------------------------

sgs.ai_skill_invoke.newtongwo = function(self, data)
	return true
end



--嘲讽
sgs.ai_chaofeng.shaye_rougumeisheng = 0

--------------------------------------------------
--焚心
--------------------------------------------------

sgs.ai_view_as.fenxin_S = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("fire_slash:fenxin_S[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local fenxin_S_skill = {}
fenxin_S_skill.name = "fenxin_S"
table.insert(sgs.ai_skills, fenxin_S_skill)
fenxin_S_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local red_card
	self:sortByUseValue(cards, true)

	local useAll = false
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao") then
		disCrossbow = true
	end

	local nuzhan_equip = false
	local nuzhan_equip_e = false
	self:sort(self.enemies, "defense")
	if self.player:hasSkill("nuzhan") then
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange()
			and getCardsNum("Jink", enemy) < 1 then
				nuzhan_equip_e = true
				break
			end
		end
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard") and nuzhan_equip_e then
				nuzhan_equip = true
				break
			end
		end
	end

	local nuzhan_trick = false
	local nuzhan_trick_e = false
	self:sort(self.enemies, "defense")
	if self.player:hasSkill("nuzhan") and not self.player:hasFlag("hasUsedSlash") and self:getCardsNum("Slash") > 1 then
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() then
				nuzhan_trick_e = true
				break
			end
		end
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard") and nuzhan_trick_e then
				nuzhan_trick = true
				break
			end
		end
	end

	for _, card in ipairs(cards) do
		local slash = sgs.Sanguosha:cloneCard("slash")
		if card:isRed() and not card:isKindOf("Slash") and not (nuzhan_equip or nuzhan_trick)
			and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash) > 0) then
			red_card = card
			break
		end
		slash:deleteLater()
	end

	if nuzhan_equip then
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("EquipCard") then
				red_card = card
				break
			end
		end
	end

	if nuzhan_trick then
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard")then
				red_card = card
				break
			end
		end
	end

	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getEffectiveId()
		local card_str = ("fire_slash:fenxin_S[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end

function sgs.ai_cardneed.fenxin_S(to, card)
	return to:getHandcardNum() < 3 and card:isRed()
end



--嘲讽
sgs.ai_chaofeng.laila_xuelie = -1

--------------------------------------------------
--忆狩
--------------------------------------------------

sgs.ai_skill_invoke.yishou = function(self,data)
	return not self:isWeak()
end

sgs.ai_skill_discard["yishou"] = function(self, discard_num, min_num, optional, include_equip)	--yun
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	if not (self:willSkipPlayPhase() or self:willSkipDrawPhase()) then		--不被控就直接用，防御是什么能吃吗
		to_discard = dimeng_discard(self, 1, cards)
	end
	return to_discard
end

--------------------------------------------------
--祭血
--------------------------------------------------

local jixue_skill={}
jixue_skill.name="jixue"
table.insert(sgs.ai_skills,jixue_skill)
jixue_skill.getTurnUseCard=function(self,inclusive)
	if self.player:getMark("@jixue") > 0 and self.player:canDiscard(self.player, "he") then
		local red_count = 0
		for _,card in sgs.qlist(self.player:getCards("he")) do
			if card:isRed() and not card:isKindOf("Peach") and not self.player:isJilei(card) then	--桃不计数，全桃开祭血太蠢了
				red_count = red_count + 1
			end
		end
		if (red_count > 0 and self:isWeak()) or (red_count > 2 and self:getOverflow() > 2) then
			return sgs.Card_Parse("#jixue:.:")
		end
	end
end

sgs.ai_skill_use_func["#jixue"] = function(card,use,self)
	if not use.isDummy then self:speak("jixue") end
	use.card = card
end

sgs.ai_use_priority["jixue"] = 3.1	--酒为3.0杀为2.6

sgs.ai_skill_choice.jixue = function(self, choices)
	if (self:isWeak() or self.player:hasSkills(sgs.masochism_skill)) and self.player:isWounded() then
		return "jixue_recover"
	end
	return "jixue_draw"
end



--嘲讽
sgs.ai_chaofeng.xingxi_tianjiliuxing = -5

--------------------------------------------------
--星耀
--------------------------------------------------

sgs.ai_skill_invoke.xingyao = function(self,data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(use.to) do
		if self:isEnemy(p) then
			return true
		end
	end
	return false
end

--[[sgs.ai_choicemade_filter.skillInvoke.xingyao = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = findPlayerByObjName(self.room, promptlist[#promptlist - 1])
		if target then sgs.updateIntention(player, target, 10) end
	end
end]]

--------------------------------------------------
--余光
--------------------------------------------------

sgs.ai_skill_playerchosen.yuguang = function(self, targets)
	return self:findPlayerToDiscard("he", false, true, targets, false)
end




--嘲讽
sgs.ai_chaofeng.xiaomao_lairikeqi = 1

--------------------------------------------------
--辨识
--------------------------------------------------

local bianshi_skill={}
bianshi_skill.name="bianshi"
table.insert(sgs.ai_skills,bianshi_skill)
bianshi_skill.getTurnUseCard=function(self)
	if self.player:getHandcardNum() < 4 + self.player:getEquips():length() and --[[not self.player:isKongcheng()]] not self.player:isNude() and (not self.player:hasUsed("#bianshicard")) and self:canDraw() then
		return sgs.Card_Parse("#bianshicard:.:")
	end
end

sgs.ai_skill_use_func["#bianshicard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["bianshiCard"] = 2
sgs.ai_use_priority["bianshiCard"] = 0

--------------------------------------------------
--成长
--------------------------------------------------

sgs.ai_skill_invoke.chengzhang = function(self, data)
	return true
end




--嘲讽
sgs.ai_chaofeng.shayin_linglongyemo = 0

--------------------------------------------------
--魔音
--------------------------------------------------

local moyin_skill = {}
moyin_skill.name = "moyin"
table.insert(sgs.ai_skills, moyin_skill)
moyin_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#moyin") >= 1 then return end
	return sgs.Card_Parse("#moyin:.:")
end
sgs.ai_skill_use_func["#moyin"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	for _, vic in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if SkillCanTarget(vic, self.player, "moyin") then
			targets:append(vic)
		end
	end
	if not targets:isEmpty() then
		local first, second, third, forth
		
		targets = sgs.QList2Table(targets)
		self:sort(targets, "defense")
		for _, to in ipairs(targets) do
			if self:isFriend(to) and to:isKongcheng() and self:canDraw(to) then		--空城队友
				first = to
				break
			elseif self:isEnemy(to) and to:isKongcheng() and self:needKongcheng(to) then	--需要空城的敌人（夏鹤仪震怒）
				first = to
				break
			elseif self:isEnemy(to) and getCardsNum("Jink", to, self.player) > 0 then		--有明闪的敌人
				second = to
			elseif self:isFriend(to) and getCardsNum("Jink", to, self.player) == 0 and self:canDraw(to) then	--明没有闪的队友
				third = to
			elseif self:isEnemy(to) and self:isWeak(to) and to:getHandcardNum() - getCardsNum("VisibleCard", to, self.player) > 0 then	--虚弱且有未知牌的敌人
				forth = to
			end
		end
		
		local target = first or second or third or forth	--or连接多个操作数时，表达式的返回值就是从左到右第一个不为假的值，若全部操作数值都为假，则表达式的返回值为最后一个操作数
		if target then
			if use.to then
				use.to:append(target)
			end
			card_str = "#moyin:.:->"..target:objectName()
			use.card = sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_value["moyin"] = 1 --卡牌使用价值
sgs.ai_use_priority["moyin"] = sgs.ai_use_priority.Slash + 0.21 --卡牌使用优先级

sgs.ai_card_intention.moyin = function(self, card, from, tos)
    local to = tos[1]
    local intention = 0
    if to:isKongcheng() then
		if self:canDraw(to) then
			intention = -10
		else
			intention = 10
		end
	elseif to:getHandcardNum() > 3 or getCardsNum("Jink", to, from) > 0 then
		if not self:needKongcheng(to) then
			intention = 10
		end
	elseif getCardsNum("Jink", to, from) == 0 then
		if self:canDraw(to) then
			intention = -10
		end
    end
    sgs.updateIntention(from, to, intention)
end

sgs.ai_skill_cardask["@moyin_discard"] = function(self, data, pattern, target)
	local type_str = data:toString():split(":")[1]
	local color_str = data:toString():split(":")[2]
	
	local cards = {}
	for _,cd in sgs.qlist(self.player:getHandcards()) do
		if getColorString(cd) == color_str and getTypeString(cd) == type_str then
			table.insert(cards, cd)
		end
	end
	self:sortByKeepValue(cards)
	return "$"..cards[1]:getEffectiveId()
end

--------------------------------------------------
--魔音（新）
--------------------------------------------------

local newmoyin_skill = {}
newmoyin_skill.name = "newmoyin"
table.insert(sgs.ai_skills, newmoyin_skill)
newmoyin_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#newmoyin") >= 1 then return end
	return sgs.Card_Parse("#newmoyin:.:")
end
sgs.ai_skill_use_func["#newmoyin"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	self:sort(self.enemies, "handcard")
	for _, vic in ipairs(self.enemies) do
		if not vic:isKongcheng() and SkillCanTarget(vic, self.player, "newmoyin") and self.player:canEffect(vic, "newmoyin") then
			targets:append(vic)
		end
	end
	if not targets:isEmpty() then
		local first, second, third, forth
		
		for _, to in sgs.qlist(targets) do
			if not first and self.player:canSeeHandcard(to) then		--手牌可见
				first = to
			elseif not second and getCardsNum("VisibleCard", to, self.player) > 0 then	--有明牌
				second = to
			elseif not third and not self:needKongcheng(to) then	--随便一个不需要空城的敌人
				third = to
			elseif not forth then	--随便一个敌人
				forth = to
			end
		end
		
		local target = first or second or third or forth	--or连接多个操作数时，表达式的返回值就是从左到右第一个不为假的值，若全部操作数值都为假，则表达式的返回值为最后一个操作数
		if target then
			if use.to then
				use.to:append(target)
			end
			card_str = "#newmoyin:.:->"..target:objectName()
			use.card = sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_value["newmoyin"] = 1 --卡牌使用价值
sgs.ai_use_priority["newmoyin"] = sgs.ai_use_priority.Slash + 0.21 --卡牌使用优先级

sgs.ai_card_intention.newmoyin = function(self, card, from, tos)
    local to = tos[1]
    sgs.updateIntention(from, to, 10)
end

sgs.ai_skill_cardask["#newmoyin_selectcard"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards, self:isFriend(self.room:getCurrent()))
	for _, card in ipairs(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), self.player:objectName())
		if self:isFriend(self.room:getCurrent()) or not (card:hasFlag("visible") or card:hasFlag(flag)) then	--不给敌人展示其已知的牌
			return "$" .. card:getEffectiveId()
		end
	end
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_skill_askforag["newmoyin"] = function(self, card_ids)
	local to = findPlayerByFlag(self.room, "newmoyin_target_AI")
	if to then
		local handcards = to:getHandcards()
		local can_see = self.player:canSeeHandcard(to)
		self:sortIdsByValue(card_ids, "use", false)
		for _,id in ipairs(card_ids) do
			for _, c in sgs.qlist(handcards) do
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), to:objectName())
				if can_see or c:hasFlag("visible") or c:hasFlag(flag) then
					if c:getId() == id then
						return id
					end
				end
			end
		end
	end
	return card_ids[1]
end




--嘲讽
sgs.ai_chaofeng.ciyuanjiang_mengxinyindaoyuan = 0

--------------------------------------------------
--次元共振
--------------------------------------------------

sgs.ai_skill_invoke.ciyuangongzhen = function(self, data)
	if self.player:aliveCount() == 2 then
		local other = nil
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:isAdjacentTo(self.player) then
				other = p
				break
			end
		end
		if other and other:getHp() > self.player:getHp() and not self:isWeak() then
			return false
		end
	end
	return true
end

sgs.ai_skill_choice.ciyuangongzhen = function(self, choices)
	local cards = self.player:getHandcards()
	local friendNum = 0
	local friendNude = 0
	local enemyNum = 0
	local enemyNude = 0
	local unknownNum = 0
	local draw = false
	local discard = false
	local other = nil
	
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if p:getMark("ciyuangongzhen") > 0 then
			if self:isFriend(p) then
				friendNum = friendNum + 1
				if p:isNude() then
					friendNude = friendNude + 1
				end
			elseif self:isEnemy(p) then
				enemyNum = enemyNum + 1
				other = p
				if p:isNude() then
					enemyNude = enemyNude + 1
				end
				if self:getDangerousCard(to) or self:getValuableCard(to) then	--敌人有高价值牌，八说了开拆
					return "ciyuangongzhen_discard"
				end
			else
				unknownNum = unknownNum + 1
			end
		end
	end
	local total = friendNum + enemyNum + unknownNum
	
	if total == 3 then
		if friendNum > enemyNum then
			draw = true
		elseif (friendNum - friendNude) < (enemyNum - enemyNude) then
			discard = true
		else
			if self.player:getHandcardNum() >= self.player:getHp() and self.player:getHp() >= 2 then
				discard = true
			else
				draw = true
			end
		end
	elseif total == 2 then
		if enemyNum == 0 then
			draw = true
		else
			if self.player:isNude() and not other:isNude() then
				return "ciyuangongzhen_discard"
			end
			if self.player:getHp() > other:getHp() and self.player:getHandcardNum() >= 2 and not other:isNude() then
				discard = true
			elseif self.player:getHp() > other:getHp() and (self.player:getHandcardNum() < 2 or other:isNude()) then
				draw = true
			elseif self.player:getHp() == other:getHp() then
				if self.player:getHandcardNum() >= 2 and not other:isNude() then
					discard = true
				else
					draw = true
				end
			elseif other:getHp() > self.player:getHp() and self:isWeak() then
				draw = true
			end
		end
	else
		draw = true
	end
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if p:getMark("ciyuangongzhen") > 0 then
			if self:isFriend(p) and not self:canDraw(p) then	--队友不能摸就不选摸牌
				draw = false
			end
		end
	end
	if draw then
		return "ciyuangongzhen_drawcard"
	end
	if discard then
		return "ciyuangongzhen_discard"
	end
	return "cancel"
end



--嘲讽
sgs.ai_chaofeng.kuji_chaoyongyuge = 1

--------------------------------------------------
--低吟
--------------------------------------------------

local function get_handcard_suit(cards)
	if #cards == 0 then return sgs.Card_NoSuit end
	if #cards == 1 then return cards[1]:getSuit() end
	local black = false
	if cards[1]:isBlack() then black = true end
	for _, c in ipairs(cards) do
		if black ~= c:isBlack() then return sgs.Card_NoSuit end
	end
	return black and sgs.Card_NoSuitBlack or sgs.Card_NoSuitRed
end

local diyin_skill = {}
diyin_skill.name = "diyin"
table.insert(sgs.ai_skills, diyin_skill)
diyin_skill.getTurnUseCard = function(self, inclusive)
	sgs.ai_use_priority["diyin"] = 1.5
	if self.player:getMark("diyin_used") > 0 or self.player:isKongcheng() then return end
	local cards = self.player:getHandcards()
	local allcard = {}
	cards = sgs.QList2Table(cards)
	local suit = get_handcard_suit(cards)
	local aoename = "savage_assault|archery_attack"
	local aoenames = aoename:split("|")
	local aoe
	local i
	local good, bad = 0, 0
	local caocao = self.room:findPlayerBySkillName("jianxiong")
	local diyintrick = "savage_assault|archery_attack|duel|fire_attack"
	local diyintricks = diyintrick:split("|")
	local aoe_available, ge_available, ex_available = true, true, true
	local dl_available, fa_available = true, true
	for i = 1, #diyintricks do
		local forbiden = diyintricks[i]
		forbid = sgs.Sanguosha:cloneCard(forbiden, suit)
		if self.player:isCardLimited(forbid, sgs.Card_MethodUse, true) or not forbid:isAvailable(self.player) then
			if forbid:isKindOf("AOE") then aoe_available = false end
			if forbid:isKindOf("GlobalEffect") then ge_available = false end
			if forbid:isKindOf("ExNihilo") then ex_available = false end
			if forbid:isKindOf("Duel") then dl_available = false end
			if forbid:isKindOf("FireAttack") then fa_available = false end
		end
		forbid:deleteLater()
	end
	if self.player:getMark("diyin_used") > 0 then return end
	for _, friend in ipairs(self.friends) do
		if friend:isWounded() then
			good = good + 10 / friend:getHp()
			if friend:isLord() then good = good + 10 / friend:getHp() end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if enemy:isWounded() then
			bad = bad + 10 / enemy:getHp()
			if enemy:isLord() then
				bad = bad + 10 / enemy:getHp()
			end
		end
	end

	local can_use = false
	local total_keep_value = 0
	for _, card in ipairs(cards) do
		table.insert(allcard, card:getId())
		total_keep_value = total_keep_value + self:getKeepValue(card)
		if self:willUse(self.player, card) then
			can_use = true
		end
	end

	if #allcard > 1 then sgs.ai_use_priority["diyin"] = 0 end
	if self.player:getHandcardNum() == 1 or (self.player:getHandcardNum() <= 3 and not can_use) then
		if aoe_available then
			for i = 1, #aoenames do
				local newdiyin = aoenames[i]
				aoe = sgs.Sanguosha:cloneCard(newdiyin)
				if self:getAoeValue(aoe) > 0 then
					aoe:deleteLater()
					--local parsed_card = sgs.Card_Parse("#diyin:" .. table.concat(allcard, "+") .. ":" .. newdiyin)
					local parsed_card = sgs.Card_Parse(newdiyin .. ":diyin[no_suit:0]=".. table.concat(allcard, "+"))
					return parsed_card
				end
				aoe:deleteLater()
			end
		end
		
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		for _,card in sgs.qlist(self.player:getHandcards()) do
			duel:addSubcard(card)
		end
		duel:setSkillName("diyin")
		if self:willUse(self.player, duel, false, false, true) and dl_available then
			duel:deleteLater()
			local parsed_card = sgs.Card_Parse("duel:diyin[no_suit:0]=".. table.concat(allcard, "+"))
			return parsed_card
		end
		duel:deleteLater()
		
		if total_keep_value < 6 and fa_available then
			local parsed_card = sgs.Card_Parse("fire_attack:diyin[no_suit:0]=".. table.concat(allcard, "+"))
			return parsed_card
		end
	end

	if aoe_available then
		for i = 1, #aoenames do
			local newdiyin = aoenames[i]
			aoe = sgs.Sanguosha:cloneCard(newdiyin)
			if self:getAoeValue(aoe) > -5 and caocao and self:isFriend(caocao) and caocao:getHp() > 1 and not self:willSkipPlayPhase(caocao)
				and not self.player:hasSkill("jueqing") and self:aoeIsEffective(aoe, caocao, self.player) then
				aoe:deleteLater()
				--local parsed_card = sgs.Card_Parse("#diyin:" .. table.concat(allcard, "+") .. ":" .. newdiyin)
				local parsed_card = sgs.Card_Parse(newdiyin .. ":diyin[no_suit:0]=".. table.concat(allcard, "+"))
				return parsed_card
			end
			aoe:deleteLater()
		end
	end
end

sgs.ai_skill_use_func["#diyin"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local diyincard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	diyincard:setSkillName("diyin")
	self:useTrickCard(diyincard, use)
	diyincard:deleteLater()
	if use.card then
		for _, acard in sgs.qlist(self.player:getHandcards()) do
			if isCard("Peach", acard, self.player) and self.player:getHandcardNum() > 1 and self.player:isWounded()
				and not self:needToLoseHp(self.player) then
					use.card = acard
					return
			end
		end
		use.card = card
	end
end

sgs.ai_use_priority["diyin"] = 1.5




--嘲讽
sgs.ai_chaofeng.jiuma_hanshixianggong = 0

--------------------------------------------------
--制冷
--------------------------------------------------

--[[sgs.ai_skill_discard["zhileng"] = function(self, discard_num, min_num, optional, include_equip)	--yun
	local need_avoid = false
	local data = self.player:getTag("zhileng")
	local damage = data:toDamage()
	if damage and self:damageIsEffective_(damage) and not self:getDamagedEffects(damage.to, damage.from, damage.card and damage.card:isKindOf("Slash"))
		and not self:needToLoseHp(damage.to, damage.from, damage.card and damage.card:isKindOf("Slash")) then
		need_avoid = true
	end
	
	if need_avoid then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		local to_discard = {}
		to_discard = dimeng_discard(self, 2, cards)
		return to_discard
	end
	return {}
end]]

sgs.ai_skill_discard["zhileng"] = function(self, discard_num, min_num, optional, include_equip)
	local data = self.player:getTag("zhileng")
	local damage = data:toDamage()
	return nosganglie_discard_EX(self, discard_num, min_num, optional, include_equip, damage.from, true)	--引用进化后的最强刚烈ai（误）
end



--嘲讽
sgs.ai_chaofeng.shixiaoya_xianyadan = -1

--------------------------------------------------
--浅唱
--------------------------------------------------

local function get_handcard_suit(cards)
	if #cards == 0 then return sgs.Card_NoSuit end
	if #cards == 1 then return cards[1]:getSuit() end
	local black = false
	if cards[1]:isBlack() then black = true end
	for _, c in ipairs(cards) do
		if black ~= c:isBlack() then return sgs.Card_NoSuit end
	end
	return black and sgs.Card_NoSuitBlack or sgs.Card_NoSuitRed
end

local qianchang_skill = {}
qianchang_skill.name = "qianchang"
table.insert(sgs.ai_skills, qianchang_skill)
qianchang_skill.getTurnUseCard = function(self, inclusive)
	sgs.ai_use_priority["qianchang"] = 1.5
	if self.player:getMark("qianchang_used") > 0 or self.player:isKongcheng() then return end
	local cards = self.player:getHandcards()
	local allcard = {}
	cards = sgs.QList2Table(cards)
	local suit = get_handcard_suit(cards)
	local aoename = "savage_assault|archery_attack"
	local aoenames = aoename:split("|")
	local aoe
	local i
	local good, bad = 0, 0
	local caocao = self.room:findPlayerBySkillName("jianxiong")
	local qianchangtrick = "amazing_grace|collateral|dismantlement|ex_nihilo|fudichouxin|god_salvation|iron_chain|snatch"
	local qianchangtricks = qianchangtrick:split("|")
	local aoe_available, ge_available, ex_available = true, true, true
	local dl_available, fa_available = true, true
	for i = 1, #qianchangtricks do
		local forbiden = qianchangtricks[i]
		forbid = sgs.Sanguosha:cloneCard(forbiden, suit)
		if self.player:isCardLimited(forbid, sgs.Card_MethodUse, true) or not forbid:isAvailable(self.player) then
			if forbid:isKindOf("AOE") then aoe_available = false end
			if forbid:isKindOf("GlobalEffect") then ge_available = false end
			if forbid:isKindOf("ExNihilo") then ex_available = false end
			if forbid:isKindOf("Snatch") then sn_available = false end
			if forbid:isKindOf("Dismantlement") then di_available = false end
		end
		forbid:deleteLater()
	end
	if self.player:getMark("qianchang_used") > 0 then return end
	for _, friend in ipairs(self.friends) do
		if friend:isWounded() then
			good = good + 10 / friend:getHp()
			if friend:isLord() then good = good + 10 / friend:getHp() end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if enemy:isWounded() then
			bad = bad + 10 / enemy:getHp()
			if enemy:isLord() then
				bad = bad + 10 / enemy:getHp()
			end
		end
	end

	local can_use = false
	local total_keep_value = 0
	for _, card in ipairs(cards) do
		table.insert(allcard, card:getId())
		total_keep_value = total_keep_value + self:getKeepValue(card)
		if self:willUse(self.player, card) then
			can_use = true
		end
	end
	local godsalvation = sgs.Sanguosha:cloneCard("god_salvation", suit, 0)
	local snatch_card = sgs.Sanguosha:cloneCard("snatch", suit, 0)
	local dismantlement_card = sgs.Sanguosha:cloneCard("dismantlement", suit, 0)

	if #allcard > 1 then sgs.ai_use_priority["qianchang"] = 0 end
	if self.player:getHandcardNum() == 1 or (self.player:getHandcardNum() <= 3 and not can_use) then
		if ge_available and self:willUseGodSalvation(godsalvation) then
			godsalvation:deleteLater()
			local parsed_card = sgs.Card_Parse("god_salvation:qianchang[no_suit:0]=".. table.concat(allcard, "+"))
			return parsed_card
		end
		
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if sn_available and snatch_card:isAvailable(self.player) and not self.room:isProhibited(self.player, p, snatch_card) and snatch_card:targetFilter(sgs.PlayerList(), p, self.player) then
				if (self:isEnemy(p) and self:getDangerousCard(p) or self:getValuableCard(p)) or (self:isFriend(p) and (p:containsTrick("indulgence") or p:containsTrick("supply_shortage"))) then
					snatch_card:deleteLater()
					local parsed_card = sgs.Card_Parse("snatch:qianchang[no_suit:0]=".. table.concat(allcard, "+"))
					return parsed_card
				end
			end
		end
		
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if di_available and dismantlement_card:isAvailable(self.player) and not self.room:isProhibited(self.player, p, dismantlement_card) and dismantlement_card:targetFilter(sgs.PlayerList(), p, self.player) then
				if (self:isEnemy(p) and self:getDangerousCard(p)) or (self:isFriend(p) and (p:containsTrick("indulgence") or p:containsTrick("supply_shortage")))  then
					dismantlement_card:deleteLater()
					local parsed_card = sgs.Card_Parse("dismantlement:qianchang[no_suit:0]=".. table.concat(allcard, "+"))
					return parsed_card
				end
			end
		end
		
		godsalvation:deleteLater()
		snatch_card:deleteLater()
		dismantlement_card:deleteLater()
		
		if total_keep_value < 6 and ex_available then
			local parsed_card = sgs.Card_Parse("ex_nihilo:qianchang[no_suit:0]=".. table.concat(allcard, "+"))
			return parsed_card
		end
	end
end

sgs.ai_skill_use_func["#qianchang"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local qianchangcard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	qianchangcard:setSkillName("qianchang")
	self:useTrickCard(qianchangcard, use)
	qianchangcard:deleteLater()
	if use.card then
		for _, acard in sgs.qlist(self.player:getHandcards()) do
			if isCard("Peach", acard, self.player) and self.player:getHandcardNum() > 1 and self.player:isWounded()
				and not self:needToLoseHp(self.player) then
					use.card = acard
					return
			end
		end
		use.card = card
	end
end

sgs.ai_use_priority["qianchang"] = 1.5

--------------------------------------------------
--明贤
--------------------------------------------------

sgs.ai_skill_cardask["@mingxian_give"] = function(self, data, pattern, target)
	local target = data:toPlayer()
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	if self:isFriend(target) then
		if not self:findLeijiTarget(target, 50, self.player) then return "." end
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				return "$" .. card:getEffectiveId()
			end
		end
	else
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end

sgs.ai_slash_prohibit["mingxian"] = function(self, from, to)
	if self:isFriend(to, from) then return false end
	local slash_num
	if from:objectName() == self.player:objectName() then
		slash_num = self:getCardsNum("Slash")
	else
		return false	--仅由出杀者本身做判断（不然本体会以为杀无效所以不闪）
	end
	for _, c in sgs.qlist(from:getHandcards()) do
		if c:isKindOf("Slash") and c:isBlack() and not c:isKindOf("FireSlash") and not c:isKindOf("ThunderSlash") then
			self.player:setFlags("slashProhibit_stack_overflow")	--避免与slashProhibit互相调用无限循环
			if self:slashIsEffective(c, to) and not self:slashProhibit(c, to) then
				self.player:setFlags("-slashProhibit_stack_overflow")
				return false
			end
			self.player:setFlags("-slashProhibit_stack_overflow")
		end
	end
	if self.player:getHandcardNum() == 2 then
		local needkongcheng = self:needKongcheng()
		if needkongcheng then return slash_num < 2 end
	end
	return slash_num < 2
end



--嘲讽
sgs.ai_chaofeng.nia_youeryuanyuanzhang = -1

--------------------------------------------------
--抚育
--------------------------------------------------

sgs.ai_skill_cardask["@fuyu_show"] = function(self, data, pattern, target)
	local myself = data:toPlayer()
	if self:isFriend(myself) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValue(cards, true)
		for _, card in ipairs(cards) do
			return "$" .. card:getEffectiveId()
		end
		return "$" .. cards[1]:getEffectiveId()
	end
	return "."
end

sgs.ai_skill_cardask["@fuyu_swap"] = function(self, data, pattern, target)
	local from = data:toPlayer()
	if not self:isEnemy(from) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(cards, false)
		for _, card in ipairs(cards) do
			return "$" .. card:getEffectiveId()
		end
		return "$" .. cards[1]:getEffectiveId()
	else
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(cards, true)
		for _, card in ipairs(cards) do
			return "$" .. card:getEffectiveId()
		end
		return "$" .. cards[1]:getEffectiveId()
	end
end

--------------------------------------------------
--新抚育
--------------------------------------------------

sgs.ai_skill_use["@@newfuyu"] = function(self, prompt)
    local targets = {}
	local targets_list = sgs.SPlayerList()
	if not self.player:isKongcheng() and (not self:isWeak(self.player, true) or self:needToLoseHp(self.player, self.player, false, false, true)) then	--优先点自己的情况：自己不需要回血且有手牌
		table.insert(targets, self.player:objectName())
		targets_list:append(self.player)
	end
	self:sort(self.friends, "handcard")
    for i = #self.friends, 1, -1 do	--倒序
		local friend = self.friends[i]
        if targets_list:length() < self.player:getMark("newfuyu") and not friend:isKongcheng() and self:canDraw(friend) and self.player:canEffect(friend, "fuyu") and not table.contains(targets, friend:objectName()) then
            table.insert(targets, friend:objectName())
			targets_list:append(friend)
        end 
    end
	self:sort(self.enemies, "handcard")
    for i = 1, #self.enemies, 1 do
		local enemy = self.enemies[i]
        if targets_list:length() < self.player:getMark("newfuyu") and not enemy:isKongcheng() and not self:canDraw(friend) and self.player:canEffect(enemy, "fuyu") and not table.contains(targets, enemy:objectName()) then
            table.insert(targets, enemy:objectName())
			targets_list:append(enemy)
        end 
    end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do	--对无手牌角色敌我效果相同
		if targets_list:length() < self.player:getMark("newfuyu") and p:isKongcheng() and self.player:canEffect(p, "fuyu") and not table.contains(targets, p:objectName()) then
            table.insert(targets, p:objectName())
			targets_list:append(p)
		end
	end
    return "#newfuyu:.:->"..table.concat(targets, "+")
end

sgs.ai_skill_cardask["@newfuyu_dis"] = function(self, data, pattern, target)
	local target = data:toPlayer()
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	if self:isFriend(target) then
		for _, card in ipairs(cards) do
			if self:isWeak(target) or target:getLostHp() >= 3 then
				if card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") then
					return "$" .. card:getEffectiveId()
				else continue end
			else continue end
		end
		for _, card in ipairs(cards) do
			if self:isWeak(target) or target:getLostHp() >= 3 then
				if card:getSuit() == sgs.Card_Heart then
					return "$" .. card:getEffectiveId()
				else continue end
			else continue end
		end
		for _, card in ipairs(cards) do
			if target:getLostHp() == 1 and not self:isWeak(target) then
				if card:getSuit() == sgs.Card_Heart then
					continue
				end
				return "$" .. card:getEffectiveId()
			end
		end
		for _, card in ipairs(cards) do
			return "$" .. card:getEffectiveId()
		end
	else
		for _, card in ipairs(cards) do
			if target:faceUp()then
				if card:getSuit() == sgs.Card_Heart then continue end
				return "$" .. card:getEffectiveId()
			else
				return "$" .. card:getEffectiveId()
			end
		end
		for _, card in ipairs(cards) do
			return "$" .. card:getEffectiveId()
		end
	end
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_card_intention.newfuyu = -10

sgs.newfuyu_suit_value = {
	heart = 6,
}



--嘲讽
sgs.ai_chaofeng.longyueyou_jilvjinglingmao = 0

--------------------------------------------------
--占梦
--------------------------------------------------

sgs.ai_skill_playerchosen.zhanmeng = function(self, targetlist)
	local cards = sgs.CardList()
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player, cards)
	
	if max_card then
		targetlist = sgs.QList2Table(targetlist)
		self:sort(targetlist, "handcard")
		
		local first, second, third
		
		for _, p in ipairs(targetlist) do
			if self:isEnemy(p) and not self:needToThrowHandcard(p, 1) then
				if self:getMaxCard(p) and max_card:getNumber() > self:getMaxCard(p):getNumber() and not first then
					first = p
				elseif self:isWeak(p) and not max_card:isKindOf("Jink") and not second then
					second = p
				elseif self:getOverflow() >= 0 and (not self:isWeak() or self:willSkipPlayPhase() or max_card:getNumber() > 10) and p:getHandcardNum() <= 2 and not third then
					third = p
				end
			end
		end
		return first or second or third
	end
	return nil
end

sgs.ai_playerchosen_intention.zhanmeng = function(self, from, to)
	if not self:needToThrowHandcard(to, 1) then
		local intention = 10
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_skill_cardask["@zhanmeng_put"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_cardneed.zhanmeng = function(to, card, self)
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	end
end

sgs.ai_skill_invoke.zhanmeng = function(self, data)
	if data:toString() == "choice:" then
		return false
	end
	return true
end

--------------------------------------------------
--游憩
--------------------------------------------------

sgs.ai_skill_invoke.youqi = function(self, data)
	local pindian = data:toPindian()
	if not pindian.to then	--和牌堆拼点的情况，直接用
		return true
	end
	if pindian.reason == "zhanmeng" and self.player:objectName() == pindian.from:objectName() then	--拼点原因是占梦
		local is_user = self.player:objectName() == pindian.from:objectName()
		if pindian.success then
			if pindian.to:isNude() then		--占梦赢但对方无牌可弃，赚一张
				return is_user
			end
		else
			if pindian.from:isNude() then		--占梦没赢但自己无牌可弃，不发动
				return is_user
			end
		end
	end
	if self:isFriend(pindian.from, pindian.to) then
		return true
	end
	if self.player:objectName() == pindian.from:objectName() and self:getUseValue(pindian.from_card) < self:getUseValue(pindian.to_card) then
		return true
	elseif self.player:objectName() == pindian.to:objectName() and self:getUseValue(pindian.from_card) > self:getUseValue(pindian.to_card) then
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.xiongzai_beijixingdeshouwangzhe = -1

--------------------------------------------------
--星熊
--------------------------------------------------

sgs.ai_cardneed.xingxiong = function(to, card, self)
	return card:isKindOf("Slash") or card:isKindOf("Analeptic") or card:isKindOf("Spear")
end

--------------------------------------------------
--望乡
--------------------------------------------------

sgs.ai_skill_invoke.wangxiang = function(self, data)
	if self:isWeak(self.player, true) or self.player:getMark("wangxiang_hp") - self.player:getHp() > 1 then
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.xingmengzhenxue_rongyixiaohu = 0

--------------------------------------------------
--狐尾扇
--------------------------------------------------

sgs.ai_skill_invoke.huweishan = function(self, data)
	if not self:canDraw(self.player) then
		return false
	end
	return true
end

sgs.ai_skill_invoke.huweishan_throw = function(self, data)
	local handcards = self.player:getHandcards()
	local card_get
	for _, cd in sgs.qlist(handcards) do
		if cd:hasFlag("huweishan_get") then
			card_get = cd
			handcards:removeOne(cd)
			break
		end
	end
	if card_get:isKindOf("Peach") or ((card_get:isKindOf("Jink") or card_get:isKindOf("Analeptic")) and self:isWeak() and self:getOverflow() <= 0) then
		return false
	end
	for _, cd in sgs.qlist(handcards) do
		if cd:isKindOf("Slash") and self:willUse(self.player, cd) then
			return true
		end
	end
	return false
end

sgs.ai_cardneed.huweishan = function(to, card, self)
	return card:isKindOf("Slash")
end




--嘲讽
sgs.ai_chaofeng.yuexi_ruoyuelongnv = -1

--------------------------------------------------
--婉龙
--------------------------------------------------

sgs.ai_skill_invoke.wanlong = function(self, data)
	return true
end

sgs.ai_skill_askforag["wanlong"] = function(self, card_ids)
	self:sortIdsByValue(card_ids, "use", false)
	return card_ids[1]
end

--------------------------------------------------
--月潮
--------------------------------------------------

sgs.ai_skill_playerchosen.yuechao = function(self, targetlist)
	local target = self:findPlayerToDiscard("ej", true, false, targetlist, false)
	if target and targetlist:contains(target) then
		return target
	end
	return nil
end

sgs.ai_playerchosen_intention.yuechao = function(self, from, to)
	local intention = 10
	if not self:needKongcheng(to) and not to:hasSkills(sgs.need_equip_skill) and to:getJudgingArea():isEmpty() then
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_skill_choice["yuechao"] = function(self, choices, data)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	
	local target_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:hasFlag("yuechao") then
			table.insert(target_cards, cd)
		end
	end
	if #target_cards == 0 then return end
	
	self:sortByUseValue(target_cards, true)
	target_cards = sgs.reverse(target_cards)
	
	for _,target_card in ipairs(target_cards) do
		if target_card:targetFixed() then
			--if target_card:isKindOf("EquipCard") then
			--	local equip_index = target_card:getRealCard():toEquipCard():location()
			--	if self.player:getEquip(equip_index) == nil and self.player:hasEquipArea(equip_index) then
			--		return "yuechao_use"
			--	end
			--end
			if target_card:isKindOf("EquipCard") and self:willUse(self.player, target_card) then
				return "yuechao_use"
			end
			if target_card:isKindOf("Armor") then
				local equip_index = target_card:getRealCard():toEquipCard():location()
				if self.player:getEquip(equip_index) ~= nil and self.player:hasEquipArea(equip_index) and self:needToThrowArmor() then
					return "yuechao_use"
				end
			end
			if target_card:isKindOf("SavageAssault") then
				local savage_assault = sgs.Sanguosha:cloneCard("SavageAssault")
				if self:getAoeValue(savage_assault) > 0 then
					savage_assault:deleteLater()
					return "yuechao_use"
				end
				savage_assault:deleteLater()
			end
			if target_card:isKindOf("ArcheryAttack") then
				local archery_attack = sgs.Sanguosha:cloneCard("ArcheryAttack")
				if self:getAoeValue(archery_attack) > 0 then
					archery_attack:deleteLater()
					return "yuechao_use"
				end
				archery_attack:deleteLater()
			end
			if target_card:isKindOf("Peach") and self.player:isWounded() then
				return "yuechao_use"
			end
			if target_card:isKindOf("ExNihilo") then
				return "yuechao_use"
			end
		elseif target_card:isKindOf("TrickCard") then
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(target_card, dummyuse)
			if not dummyuse.to:isEmpty() then
				return "yuechao_use"
			end
		elseif target_card:isKindOf("Slash") then
			local slash = target_card
			for _,enemy in ipairs(self.enemies) do	--yun
				if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) and self.player:canSlash(enemy, slash, true) then
					return "yuechao_use"
				end
			end
		end
		if (self:needKongcheng() and self.player:getHandcardNum() == 1) or hasManjuanEffect(self.player) then
			return "yuechao_use"
		end
	end
	return "cancel"
end

sgs.ai_skill_use["@@yuechao!"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	
	local target_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:hasFlag("yuechao") then
			table.insert(target_cards, cd)
		end
	end
	if #target_cards == 0 then return end
	
	self:sortByUseValue(target_cards, true)
	target_cards = sgs.reverse(target_cards)
	
	for _,target_card in ipairs(target_cards) do
		if target_card:targetFixed() then
			return target_card:toString()
		else
			if target_card:isKindOf("Slash") then	--yun
				local to = self:findPlayerToSlash(true, target_card, nil, true)		--距离限制、卡牌、角色限制、必须选择
				return target_card:toString() .. "->" .. to:objectName()
			end
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(target_card, dummyuse)
			local targets = {}
			if not dummyuse.to:isEmpty() then
				for _, p in sgs.qlist(dummyuse.to) do
					table.insert(targets, p:objectName())
				end
				return target_card:toString() .. "->" .. table.concat(targets, "+")
			else		--强制选择随机目标
				local targets_list = sgs.PlayerList()
				for _, target in sgs.qlist(self.room:getAlivePlayers()) do
					targets_list:append(target)
				end
				local targets = {}
				for _,p in sgs.qlist(self.room:getAlivePlayers()) do
					if target_card:targetFilter(targets_list, p, self.player) and not sgs.Self:isProhibited(p, target_card) then
						table.insert(targets, p:objectName())
					end
				end
				if #targets > 0 then
					return target_card:toString() .. "->" .. targets[math.random(1,#targets)]
				end
			end
		end
	end
	return "."
end

sgs.ai_need_damaged.yuechao = function (self, attacker, player)
	if player:getPhase() == sgs.Player_NotActive and not player:getHandcardNum() == 1 and (not self:isWeak(player) or self:getAllPeachNum(player) > 0) then
		local target = self:findPlayerToDiscard("ej", true, false, self.room:getAlivePlayers(), false, player)
		if target then
			return true
		end
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.youqimuye_ddjuedouzhe = -1

--------------------------------------------------
--疾驰
--------------------------------------------------

sgs.ai_view_as.jichi = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place == sgs.Player_PlaceHand or card_place == sgs.Player_PlaceEquip) and card:isKindOf("EquipCard") and not card:hasFlag("using") then
		return ("slash:jichi[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local jichi_skill = {}
jichi_skill.name = "jichi"
table.insert(sgs.ai_skills, jichi_skill)
jichi_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local equip_card
	self:sortByUseValue(cards, true)

	local useAll = false
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao|xingxiong") then
		disCrossbow = true
	end

	for _, card in ipairs(cards) do
		local slash = sgs.Sanguosha:cloneCard("slash")
		if card:isKindOf("EquipCard")
			and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash) > 0) then
			equip_card = card
			break
		end
		slash:deleteLater()
	end

	if equip_card then
		local suit = equip_card:getSuitString()
		local number = equip_card:getNumberString()
		local card_id = equip_card:getEffectiveId()
		local card_str = ("slash:jichi[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end

function sgs.ai_cardneed.jichi(to, card)
	return card:isKindOf("EquipCard")
end

--------------------------------------------------
--升华
--------------------------------------------------

sgs.ai_skill_choice.shenghua = function(self, choices)
	local has_judge_character = false
	for _, target in sgs.qlist(self.room:getAlivePlayers()) do
		if target:isAlive() and target:hasSkills(sgs.judge_reason) then
			has_judge_character = true
			break
		end
	end
	if not self.player:getJudgingArea():isEmpty() or has_judge_character then
		return "shenghua2"
	end
	return "shenghua1"
end

sgs.ai_need_damaged.shenghua = function (self, attacker, player)
	if player:getHp() == 2 and player:getMark("shenghua") == 0 then
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.xinshiakane_huaxingzhimao = 1

--------------------------------------------------
--月见
--------------------------------------------------

local yuejian_akane_skill={}
yuejian_akane_skill.name="yuejian_akane"
table.insert(sgs.ai_skills,yuejian_akane_skill)
yuejian_akane_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#yuejian_akane") < 2 and not self.player:isKongcheng() and not self:needBear(self.player, false, nil) then
		return sgs.Card_Parse("#yuejian_akane:.:")
	end
end
sgs.ai_skill_use_func["#yuejian_akane"] = function(card, use, self)
	local cards = {}
	for _, card in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if card:isKindOf("TrickCard") and (not card:hasFlag("&mail") or self:getOverflow() > 0) and not self:needBearCard(card, self.player, self:isWeak(self.player, true)) then
			table.insert(cards, card)
		end
	end
	if #cards == 0 then
		return
	end
	self:sortByUseValue(cards, false)
	
	local card, target_need = self:getCardNeedPlayer(cards, false)
	if target_need and target_need:isAlive() and card and self:canDraw(target_need) and self.player:canEffect(target_need, "yuejian_akane") and not self:willSkipPlayPhase(target_need) then	--有需要某牌的队友，直接给
		if use.to then
			use.to:append(target_need)
		end
		card_str = "#yuejian_akane:"..card:getEffectiveId()..":->"..target_need:objectName()
		use.card = sgs.Card_Parse(card_str)
		return
	end
	
	local first, second
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend) and not self:willSkipPlayPhase(friend) and self.player:canEffect(friend, "yuejian_akane") then
			if not first then
				local no_mail = true
				for _,cd in sgs.qlist(friend:getHandcards()) do
					if cd:hasFlag("&mail") then
						no_mail = false
						break
					end
				end
				if no_mail then
					first = friend
				end
			end
			if not second then
				second = friend
			end
			if first and second then
				break
			end
		end
	end
	
	local target = first or second
	if target then
		local card_str = "#yuejian_akane:"..cards[1]:getEffectiveId()..":->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
		return
	end
end

sgs.ai_use_priority["yuejian_akane"] = 10

sgs.ai_card_intention.yuejian_akane = function(self, card, from, tos)
	if #tos > 0 then
		for _,to in ipairs(tos) do
			if self:canDraw(to) then
				sgs.updateIntention(from, to, -10)
			end
		end
	end
	return 0
end

sgs.ai_cardneed.yuejian_akane = function(to, card, self)
	return card:isKindOf("TrickCard")
end

--------------------------------------------------
--寻绊
--------------------------------------------------

sgs.ai_skill_choice["xunban"] = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if self:isWeak() and self.player:getLostHp() > 0 and table.contains(items, "peach") then return "peach" end
		--if self.player:getLostHp() > 0 and table.contains(items, "peach") and self.player:hasSkill("shushen") and #self.friends_noself > 0 then return "peach" end
		--[[local slash = sgs.Sanguosha:cloneCard("slash")
		if self:getCardsNum("Slash") > 1 and not slash:isAvailable(self.player) and table.contains(items, "analeptic") then
			for _, enemy in ipairs(self.enemies) do
				if ((enemy:getHp() < 3 and enemy:getHandcardNum() < 3) or (enemy:getHandcardNum() < 2)) and self.player:canSlash(enemy) and not self:slashProhibit(slash, enemy, self.player)
					and self:slashIsEffective(slash, enemy, self.player) and sgs.isGoodTarget(enemy, self.enemies, self, true) then
					return "analeptic"
				end
			end
		end]]
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and sgs.isGoodTarget(enemy, self.enemies, self, true) then
				local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash")
				local fire_slash = sgs.Sanguosha:cloneCard("fire_slash")
				local ice_slash = sgs.Sanguosha:cloneCard("ice_slash")
				thunder_slash:deleteLater()
				fire_slash:deleteLater()
				ice_slash:deleteLater()
				if table.contains(items, "ice_slash")and not self:slashProhibit(ice_slash, enemy, self.player)and self:slashIsEffective(ice_slash, enemy, self.player)then
					return "ice_slash"
				end
				if table.contains(items, "fire_slash")and not self:slashProhibit(fire_slash, enemy, self.player)and self:slashIsEffective(fire_slash, enemy, self.player)then
					return "fire_slash"
				end
				if table.contains(items, "thunder_slash")and not self:slashProhibit(thunder_slash, enemy, self.player)and self:slashIsEffective(thunder_slash, enemy, self.player)then
					return "thunder_slash"
				end
				if table.contains(items, "slash")and not self:slashProhibit(slash, enemy, self.player)and self:slashIsEffective(slash, enemy, self.player)then
					return "slash"
				end
			end
		end
		if self.player:getLostHp() > 0 and table.contains(items, "peach") then return "peach" end
    end
    return "cancel"
end
sgs.ai_skill_use["@@xunban"]=function(self,prompt)
	self:updatePlayers()
	self:sort(self.enemies,"defense")
	local class_name = self.player:property("xunban_view_to_use"):toString()
	local use_card = sgs.Sanguosha:cloneCard(class_name, sgs.Card_NoSuit, 0)
	use_card:setSkillName("_xunban")
	if (use_card:targetFixed()) then
		return use_card:toString()
	else
		if string.find(class_name, "slash")then
			for _,enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, use_card, false) and not self:slashProhibit(nil, enemy) and self.player:inMyAttackRange(enemy)
				and sgs.getDefenseSlash(enemy, self) < 6 and self:slashIsEffective(use_card, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)then
					return use_card:toString() .. "->" .. enemy:objectName()
				end
			end
		end
	end
end




--嘲讽
sgs.ai_chaofeng.lichuanfeng_yuejianaidoulu = -2

--------------------------------------------------
--枫锦
--------------------------------------------------

sgs.ai_view_as.fengjin = function(card, player, card_place)
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or card_place == sgs.Player_PlaceEquip or (card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "wooden_ox") then
		if player:getMark("fengjin_used") == 0 and card:isKindOf("TrickCard") then
			return ("nullification:fengjin[%s:%s]=%d"):format("to_be_decided", 0, card_id)
		end
	end
end

sgs.ai_cardneed.fengjin = function(to, card, self)
	return card:isKindOf("TrickCard")
end

--------------------------------------------------
--寻忆
--------------------------------------------------

sgs.ai_skill_invoke.xunyi = function(self, data)
	local X = self.player:getLostHp() + 2
	if self.xunyi_thinking and self.player:getHp() > 1 then		--调整预估已损失体力值
		X = X + 1
	end
	local suit = {}
	local repeat_cardnum = 0
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if table.contains(suit, card:getSuit()) then
			repeat_cardnum = repeat_cardnum + 1
		else
			table.insert(suit, card:getSuit())
		end
	end
	local need_suits = 4-#suit
	--local exp_effective_draw = X*1.0*need_suits/4
	local Expectation
	if need_suits == 0 then
		Expectation = 0
	else
		Expectation = need_suits * (1 - math.pow(0.75, X))
	end
	if repeat_cardnum <= Expectation then
		return true
	end
	return false
end

sgs.ai_need_damaged.xunyi = function (self, attacker, player)
	if not self:isWeak(player) or self:getAllPeachNum(player) > 0 then
		self.xunyi_thinking = true	--表示正在预估
		local will_use = self:askForSkillInvoke("xunyi")
		self.xunyi_thinking = false
		return will_use
	end
	return false
end

sgs.ai_skill_use["@@xunyi!"] = function(self, prompt)
	if self.player:isNude() then return "" end
    local card_ids = {}
	local suit = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)
	for _, card in ipairs(cards) do
		if not table.contains(suit, card:getSuit()) then
			table.insert(suit, card:getSuit())
			table.insert(card_ids, card:getEffectiveId())
		end
	end
	if #card_ids > 0 then
		return "#xunyi:"..table.concat(card_ids, "+")..":"
	end
end




--嘲讽
sgs.ai_chaofeng.menglongshaozhu_bileizhen = 1

--------------------------------------------------
--遐制
--------------------------------------------------

sgs.ai_skill_playerchosen.xiazhi = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "defense")
	
	function is_xiazhi_good_target(p, just_can_slash)
		if not p:isChained() and self:needChained(p) then
			return true
		end
		
		if p:getHandcardNum() == 1 then
			return self:needKongcheng(p)
		end
		
		local cards = sgs.QList2Table(p:getCards("h"))
		local all_good_card = true
		for _, card in ipairs(cards) do
			if card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic") then
				all_good_card = false
				break
			end
		end
		if all_good_card then
			return false
		end
		
		local targets = sgs.SPlayerList()
		for _, vic in sgs.qlist(self.room:getOtherPlayers(p)) do
			if p:canSlash(vic) then
				targets:append(vic)
			end
		end
		if targets:isEmpty() then
			return false
		else
			local has_enemy = false
			local all_enemy = true
			local has_good_target = false
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
			for _, vic in sgs.qlist(targets) do
				if self:isEnemy(vic) and not self:slashProhibit(slash, vic, p) then
					has_enemy = true
					if self:isWeak(vic) or self:hasSlashAttackSkill(p) or self:hasHeavySlashDamage(p, slash, vic, false) then
						has_good_target = true
					end
				else
					all_enemy = false
				end
			end
			slash:deleteLater()
			if self:isFriend(p) then
				if just_can_slash then
					return has_enemy
				else
					return has_good_target
				end
			else
				return not all_enemy
			end
		end
	end
	
	for _, p in ipairs(targetlist) do
		if self:isFriend(p) then
			if not self:isWeak(p) and p:getHp() >= 3 and p:getHandcardNum() >= 3 and is_xiazhi_good_target(p, true) then	--状态好的队友
				return p
			elseif is_xiazhi_good_target(p, false) then
				return p
			end
		elseif self:isEnemy(p) and not is_xiazhi_good_target(p, false) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.xiazhi = function(self, from, to)
	local intention = 0
	if self:needKongcheng(to) and to:getHandcardNum() == 1 then
		intention = -10
	end
	sgs.updateIntention(from, to, intention)
end

sgs.ai_skill_use["@@xiazhi!"] = function(self, prompt, method)
	self:updatePlayers()
	
	local target_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:hasFlag("xiazhi") then
			table.insert(target_cards, cd)
		end
	end
	if #target_cards == 0 then return end
	
	self:sortByUseValue(target_cards, true)
	target_cards = sgs.reverse(target_cards)
	
	for _,target_card in ipairs(target_cards) do
		local slash = sgs.Sanguosha:cloneCard("slash", target_card:getSuit(), target_card:getNumber())
		slash:addSubcard(target_card)
		slash:setSkillName("_xiazhi")
		
		local to = self:findPlayerToSlash(true, slash, nil, true)		--距离限制、卡牌、角色限制、必须选择
		if to then
			local result = slash:toString() .. "->" .. to:objectName()
			slash:deleteLater()
			return result
		end
		slash:deleteLater()
	end
	return "."
end




--嘲讽
sgs.ai_chaofeng.shanbao_fengyaliangyou = 1

--------------------------------------------------
--寄月
--------------------------------------------------

local jiyue_skill={}
jiyue_skill.name="jiyue"
table.insert(sgs.ai_skills,jiyue_skill)
jiyue_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#jiyue") < 1 and not self.player:isNude() then
		return sgs.Card_Parse("#jiyue:.:")
	end
end
sgs.ai_skill_use_func["#jiyue"] = function(card, use, self)
	local card_names = {}
	local card_names_count = {}
	local max_count = 1
	local max_name = ""
	for _,card in sgs.qlist(self.player:getCards("he")) do
		local name = card:getClassName()
		if card:isKindOf("Peach") then	--不拿桃寄月
			continue
		end
		if card:isKindOf("Slash") then	--雷火杀都算杀
			name = "Slash"
		end
		if table.contains(card_names, name) then
			local key = AtTable(card_names, name)
			local value = card_names_count[key] + 1
			card_names_count[key] = value
			if value > max_count then
				max_count = value
				max_name = name
			end
		else
			table.insert(card_names, name)
			card_names_count[AtTable(card_names, name)] = 1
		end
	end
	if max_name == "" or max_count < 2 then return end
	local card_ids = {}
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf(max_name) and #card_ids < 4 then
			table.insert(card_ids, card:getEffectiveId())
		end
	end
	
	if #card_ids == 4 then
		local first, second
		--自订排序
		self:ironchain_fireattack_sort(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) and self.player:canEffect(enemy, "jiyue") then
				if not first and enemy:hasArmorEffect("vine") then
					first = enemy
				end
				if not second and not enemy:hasArmorEffect("silver_lion") then
					second = enemy
				end
			end
		end
		
		local target = first or second
		if target then
			if use.to then
				use.to:append(target)
			end
			card_str = "#jiyue:"..table.concat(card_ids, "+")..":->"..target:objectName()
			use.card = sgs.Card_Parse(card_str)
			return
		end
	else
		card_str = "#jiyue:"..table.concat(card_ids, "+")..":"
		use.card = sgs.Card_Parse(card_str)
		return
	end
end

sgs.ai_use_priority["jiyue"] = 8

sgs.ai_card_intention.jiyue = function(self, card, from, tos)
    local to = tos[1]
    local intention = 10
    sgs.updateIntention(from, to, intention)
end

sgs.ai_cardneed.jiyue = function(to, card, self)
	return card:isKindOf("Slash")
end




--嘲讽
sgs.ai_chaofeng.yang_xuyanyu = 2

--------------------------------------------------
--筹措
--------------------------------------------------

local choucuo_skill={}
choucuo_skill.name="choucuo"
table.insert(sgs.ai_skills,choucuo_skill)
choucuo_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#choucuo") < 1 and not self.player:isKongcheng() then
		return sgs.Card_Parse("#choucuo:.:")
	end
end

sgs.ai_skill_use_func["#choucuo"] = function(card, use, self)
	local max_discard_num = self.player:getHandcardNum()
	local target, min_friend, max_enemy

	local compare_func = function(a, b)
		return a:getEquips():length() > b:getEquips():length()
	end
	table.sort(self.enemies, compare_func)
	table.sort(self.friends, compare_func)

	self.friends = sgs.reverse(self.friends)

	for _, friend in ipairs(self.friends) do
		for _, enemy in ipairs(self.enemies) do
			if not self:hasSkills(sgs.lose_equip_skill, enemy) and not enemy:hasSkills("tuntian+zaoxian") and self.player:canEffect(friend, "choucuo") and self.player:canEffect(enemy, "choucuo") then
				local ee = enemy:getEquips():length()
				local fe = friend:getEquips():length()
				local value = self:evaluateArmor(enemy:getArmor(),friend) - self:evaluateArmor(friend:getArmor(),enemy)
					- self:evaluateArmor(friend:getArmor(),friend) + self:evaluateArmor(enemy:getArmor(),enemy)
				if math.abs(ee - fe) <= max_discard_num and ee > 0 and (ee > fe or ee == fe and value>0) then
					if self:hasSkills(sgs.lose_equip_skill, friend) then
						local X = math.abs(friend:getEquips():length() - enemy:getEquips():length())
						local ids = dimeng_discard(self, X, sgs.QList2Table(self.player:getCards("h")))
						if #ids ~= X then return end
						if use.to then
							use.to:append(friend)
							use.to:append(enemy)
						end
						local use_str = ""
						if #ids > 0 then
							use_str = "#choucuo:"..table.concat(ids, "+")..":->"
						else
							use_str = "#choucuo:.:->"
						end
						use_str = use_str..friend:objectName().."+"..enemy:objectName()
						use.card = sgs.Card_Parse(use_str)
						return
					elseif not min_friend and not max_enemy then
						min_friend = friend
						max_enemy = enemy
					end
				end
			end
		end
	end
	if min_friend and max_enemy then
		local X = math.abs(min_friend:getEquips():length() - max_enemy:getEquips():length())
		local ids = dimeng_discard(self, X, sgs.QList2Table(self.player:getCards("h")))
		if #ids ~= X then return end
		if use.to then
			use.to:append(min_friend)
			use.to:append(max_enemy)
		end
		local use_str = ""
		if #ids > 0 then
			use_str = "#choucuo:"..table.concat(ids, "+")..":->"
		else
			use_str = "#choucuo:.:->"
		end
		use_str = use_str..min_friend:objectName().."+"..max_enemy:objectName()
		use.card = sgs.Card_Parse(use_str)
		return
	end

	target = nil
	for _, friend in ipairs(self.friends) do
		if not self.player:canEffect(friend, "choucuo") then continue end
		if self:needToThrowArmor(friend) or ((self:hasSkills(sgs.lose_equip_skill, friend)
											or (friend:hasSkills("tuntian+zaoxian") and friend:getPhase() == sgs.Player_NotActive))
			and not friend:getEquips():isEmpty()) then
				target = friend
				break
		end
	end
	if not target then return end
	for _,friend in ipairs(self.friends) do
		if friend:objectName() ~= target:objectName() and self.player:canEffect(friend, "choucuo") and math.abs(friend:getEquips():length() - target:getEquips():length()) <= max_discard_num then
			local X = math.abs(friend:getEquips():length() - target:getEquips():length())
			local ids = dimeng_discard(self, X, sgs.QList2Table(self.player:getCards("h")))
			if #ids ~= X then return end
			if use.to then
				use.to:append(friend)
				use.to:append(target)
			end
			local use_str = ""
			if #ids > 0 then
				use_str = "#choucuo:"..table.concat(ids, "+")..":->"
			else
				use_str = "#choucuo:.:->"
			end
			use_str = use_str..friend:objectName().."+"..target:objectName()
			use.card = sgs.Card_Parse(use_str)
			return
		end
	end
end

sgs.ai_use_priority["choucuo"] = sgs.ai_use_priority.Dismantlement + 0.1
sgs.dynamic_value.control_card["choucuo"] = true

sgs.ai_card_intention.choucuo = function(self,card, from, to)
	local compare_func = function(a, b)
		return a:getEquips():length() < b:getEquips():length()
	end
	table.sort(to, compare_func)
	for i = 1, 2, 1 do
		if to[i]:hasArmorEffect("silver_lion") then
			sgs.updateIntention(from, to[i], -10)
			break
		end
	end
	if to[1]:getEquips():length() < to[2]:getEquips():length() then
		sgs.updateIntention(from, to[1], -10)
	end
end



--嘲讽
sgs.ai_chaofeng.fangnaitui_yinyangmeiying = -2

--------------------------------------------------
--纤柔
--------------------------------------------------

sgs.ai_skill_cardask["@xianrou_give"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Spade then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

--------------------------------------------------
--渴欲（新）
--------------------------------------------------

sgs.ai_skill_invoke.newkeyu = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) and (--[[(self.player:canSeeHandcard(target) and getCardsNum("Slash", target, self.player) > 0) or]] self:needToThrowArmor(target) or self:needToThrowHandcard(target)) then
		return true
	elseif self:isEnemy(target) and not self:needToThrowHandcard(target) then
		return true
	end
	return false
end

sgs.ai_skill_choice.newkeyu = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local to = findPlayerByFlag(self.room, "newkeyu_target_AI")
		if to then
			if self:isEnemy(to) and not self:needToLoseHp(to) then
				return "keyu_losehp"
			elseif self:isFriend(to) then
				if self:needToLoseHp(to) then
					return "keyu_losehp"
				elseif not self:isWeak(to) and not self:canDraw(to) then
					return "keyu_losehp"
				end
			end
		end
		return "keyu_draw"
	end
end






--嘲讽
sgs.ai_chaofeng.jiuhu_zhenzhizhaihu = -2

--------------------------------------------------
--布教
--------------------------------------------------

sgs.ai_skill_playerchosen.bujiao = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	local first, second
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if table.contains(targetlist, enemy) and not enemy:hasSkills(sgs.lose_hp_skills) then
			if not first and (self:getOverflow(enemy) <= -2 or self:isWeak(enemy)) then
				first = enemy
			end
			if not second then
				second = enemy
			end
			if first and second then
				break
			end
		end
	end
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if table.contains(targetlist, friend) then
			if not first and friend:hasSkills(sgs.lose_hp_skills) and self:getOverflow(friend) >= -1 and not self:isWeak(friend) then
				first = friend
				break
			end
		end
	end
	return first or second or nil
end

sgs.ai_playerchosen_intention.bujiao = function(self, from, to)
	local intention = 10
	if to:hasSkills(sgs.lose_hp_skills) then
		intention = 0
	end
	sgs.updateIntention(from, to, intention)
end




--嘲讽
sgs.ai_chaofeng.nuola_canglangzhixin = 1

--------------------------------------------------
--贵胄
--------------------------------------------------

sgs.ai_skill_use["@@guizhou"] = function(self, prompt, method)
	local others = self.room:getOtherPlayers(self.player)
	local slash = self.player:getTag("guizhou-card"):toCard()
	others = sgs.QList2Table(others)
	local source
	for _, player in ipairs(others) do
		if player:hasFlag("guizhouSlashSource") then
			source = player
			break
		end
	end
	self:sort(self.enemies, "defense")

	local doguizhou = function(who)
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not self.player:isCardLimited(card, method) and who:hasFlag("guizhouValidTarget") and self.player:canEffect(who, "guizhou") then
				if self:isFriend(who) and not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
					return "#guizhouCard:"..card:getEffectiveId()..":->"..who:objectName()
				else
					return "#guizhouCard:"..card:getEffectiveId()..":->"..who:objectName()
				end
			end
		end

		return "."
	end

	for _, enemy in ipairs(self.enemies) do
		if not (source and source:objectName() == enemy:objectName()) then
			local ret = doguizhou(enemy)
			if ret ~= "." then return ret end
		end
	end

	for _, player in ipairs(others) do
		if self:objectiveLevel(player) == 0 and not (source and source:objectName() == player:objectName()) then
			local ret = doguizhou(player)
			if ret ~= "." then return ret end
		end
	end


	self:sort(self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)


	for _, friend in ipairs(self.friends_noself) do
		if slash:isKindOf("Slash") and not self:slashIsEffective(slash, friend) or self:findLeijiTarget(friend, 50, source) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doguizhou(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if self:needToLoseHp(friend, source, true) or self:getDamagedEffects(friend, source, true) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doguizhou(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	if slash:isKindOf("Slash") and (self:isWeak() or self:hasHeavySlashDamage(source, slash)) and source:hasWeapon("axe") and source:getCards("he"):length() > 2
	  and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doguizhou(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end

	if slash:isKindOf("Slash") and (self:isWeak() or self:hasHeavySlashDamage(source, slash)) and not self:getCardId("Jink") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) or (self:hasEightDiagramEffect(friend) and getCardsNum("Jink", friend) >= 1) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doguizhou(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	return "."
end

sgs.ai_card_intention.guizhouCard = function(self, card, from, to)
	sgs.ai_guizhou_effect = true
	if not hasExplicitRebel(self.room) then sgs.ai_guizhou_user = from
	else sgs.ai_guizhou_user = nil end
end

function sgs.ai_slash_prohibit.guizhou(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:isNude() then return false end
	for _, friend in ipairs(self:getFriendsNoself(from)) do
		if friend:inMyAttackRange(to) and to:canSlash(friend, card) and self:slashIsEffective(card, friend, from) then return true end
	end
end

function sgs.ai_cardneed.guizhou(to, card)
	return to:getCards("he"):length() <= 2
end

--------------------------------------------------
--苦情
--------------------------------------------------

sgs.ai_skill_discard["kuqing"] = function(self, discard_num, min_num, optional, include_equip)	--yun
	local to_discard = {}
	local will_use = false
	local target = findPlayerByFlag(self.room, "kuqing_target_AI")
	if target and not target:isNude() then
		if self:isFriend(target) then
			if self:needToThrowArmor(target) or self:needToThrowHandcard(target) or (target:hasSkills(sgs.lose_equip_skill) and not target:getEquips():isEmpty()) then
				will_use = true
			end
		elseif self:isEnemy(target) then
			will_use = true
			if (self:needToThrowHandcard(target) and target:getEquips():isEmpty()) or ((self:needToThrowArmor(target) or target:hasSkills(sgs.lose_equip_skill)) and target:isKongcheng()) then
				will_use = false
			end
		end
	else
		return {}
	end
	
	if will_use then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		to_discard = dimeng_discard(self, 1, cards)
	end
	return to_discard
end

sgs.ai_choicemade_filter.cardChosen.kuqing = sgs.ai_choicemade_filter.cardChosen.snatch




--嘲讽
sgs.ai_chaofeng.aibing_yijinglingzhu = 2

--------------------------------------------------
--血池
--------------------------------------------------

sgs.ai_skill_askforag["xuechi"] = function(self, card_ids)	--血池，妖灵牌与手牌交换，第一步
	if not self.xuechi_exchange then
		self.xuechi_exchange = {}	--先确定此变量为list类型
	end
	
	if not self.xuechi_exchange or #self.xuechi_exchange == 0 then		--没有记录目标妖灵牌
		local X = self.player:getPile("yaoling_pile"):length()		--记录X，保证妖灵牌张数不变
		
		local all_cards = sgs.QList2Table(self.player:getCards("h"))	--获取所有手牌和妖灵牌，并转化为list格式
		for _,id in sgs.qlist(self.player:getPile("yaoling_pile")) do
			local card = sgs.Sanguosha:getCard(id)
			table.insert(all_cards, card)
		end
		
		if not self:willSkipPlayPhase() then		--按价值全部排序，价值类别由是否跳过出牌阶段决定
			self:sortByUseValue(all_cards, false)	--use value从高到低
			all_cards = sgs.reverse(all_cards)		--反转为从高到低
		else
			self:sortByKeepValue(all_cards)			--keep value从低到高
		end
		
		local to_pile_cards = {}
		
		if self.player:hasSkill("juling") and X == 13 then	--需要组聚灵牌型（十三种点数）
			local numbers = {}
			local numbers_pile_cards = {}
			for _, card in ipairs(all_cards) do		--按顺序记录首次出现的点数以及对应牌
				local number = card:getNumber()
				if not table.contains(numbers, number) then
					table.insert(numbers, number)
					table.insert(numbers_pile_cards, card)
				end
			end
			--将前13张记录的点数导入目标妖灵牌中，不足13张则其余牌用四色逻辑、普通逻辑依次补全（已选牌从all_cards中清除以免重复）
			for _, card in ipairs(numbers_pile_cards) do
				if not table.contains(to_pile_cards, card) and #to_pile_cards < X then
					table.insert(to_pile_cards, card)
					table.removeOne(all_cards, card)
				end
			end
			if #numbers == 13 then	--集齐13种点数
				goto xuechi_normal_exchange		--不再判断花色，直接补齐，毕竟你已经赢了
			end
		end
		
		if self.player:hasSkill("juling") and X >= 4 then	--需要组聚灵牌型（四种花色）
			local suits = {}
			local suits_pile_cards = {}
			
			for _, card in ipairs(to_pile_cards) do		--先记录已定位妖灵牌的牌的花色
				local suit_str = card:getSuitString()
				if not table.contains(suits, suit_str) then
					table.insert(suits, suit_str)
				end
			end
			
			for _, card in ipairs(all_cards) do		--按顺序记录首次出现的花色以及对应牌
				local suit_str = card:getSuitString()
				if not table.contains(suits, suit_str) then
					table.insert(suits, suit_str)
					table.insert(suits_pile_cards, card)
				end
			end
			if #suits == 4 then						--有四种花色，则将前四张记录的花色导入目标妖灵牌中，其余牌用普通逻辑补全（已选牌从all_cards中清除以免重复）
				for _, card in ipairs(suits_pile_cards) do
					if not table.contains(to_pile_cards, card) and #to_pile_cards < X then
						table.insert(to_pile_cards, card)
						table.removeOne(all_cards, card)
					end
				end
				goto xuechi_normal_exchange		--这里本来不用写goto的，不过为了对称= =
			end
		end
		
::xuechi_normal_exchange::
		--以下是普通的交换逻辑
		for _, card in ipairs(all_cards) do		--按价值从低到高顺序，将所有牌中的前X张牌记录为目标妖灵牌牌型
			if #to_pile_cards < X then
				if not table.contains(to_pile_cards, card) then
					table.insert(to_pile_cards, card)
				end
			else
				break
			end
		end
		
		self.xuechi_exchange = to_pile_cards	--记录目标妖灵牌牌型
	end
	
	if self.xuechi_exchange and #self.xuechi_exchange > 0 then		--若已记录目标妖灵牌，则将可选牌中在目标妖灵牌中的牌选中
		for _,id in ipairs(card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if not table.contains(self.xuechi_exchange, card) then
				return id
			end
		end
	end
	return -1
end

sgs.ai_skill_discard["xuechi"] = function(self, discard_num, min_num, optional, include_equip)	--血池，妖灵牌与手牌交换，第二步
	if self.xuechi_exchange and #self.xuechi_exchange > 0 then	--若有记录，则将手牌中不在目标妖灵牌中的牌选中
		local toDis = {}
		local cards = sgs.QList2Table(self.player:getCards("h"))
		for _, card in ipairs(cards) do
			if table.contains(self.xuechi_exchange, card) then
				table.insert(toDis, card:getEffectiveId())
			end
		end
		
		self.xuechi_exchange = {}		--清空记录，表示此次交换已完成
		if #toDis == discard_num then	--个别时候#toDis为0（小概率事件），会崩溃，这时启动应急备案
			return toDis
		else
			--self.player:speak("启动应急备案")
			return self:askForDiscard("", discard_num, min_num, optional, include_equip)
		end
	end
	return self:askForDiscard("", discard_num, min_num, optional, include_equip)
end

sgs.ai_need_damage.xuechi = function(self, player, to)		--新增 need_damage 表示需要造成伤害
	if player:getPile("yaoling_pile"):isEmpty() then	--要启动啊！
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.nainailiya_yuanbenlinyuan = -2

--------------------------------------------------
--血林
--------------------------------------------------

sgs.ai_skill_invoke.xuelin = sgs.ai_skill_invoke.ganglie	--就是刚烈（很合理）

sgs.ai_need_damaged.xuelin = function(self, attacker, player)
	if not self:isWeak(player) or self:getAllPeachNum(player) > 0 then
		return not self:isFriend(player, attacker) and not self:needToLoseHp(attacker)
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.xuelin = function(self, player, promptlist)	--照搬刚烈（很合理）
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			if not self:getDamagedEffects(damage.from, player) and not self:needToLoseHp(damage.from, player) then
				sgs.updateIntention(damage.to, damage.from, 10)
			end
		elseif self:canAttack(damage.from) then
			sgs.updateIntention(damage.to, damage.from, -10)
		end
	end
end

--------------------------------------------------
--寻腥
--------------------------------------------------

sgs.ai_skill_discard["xunxing"] = function(self, discard_num, min_num, optional, include_equip)	--yun
	local damage = self.player:getTag("xunxing_damage_AI"):toDamage()
	if not damage then
		return {}
	end
	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	if self:isEnemy(damage.from) and self:isFriend(damage.to) and not self:needToLoseHp(damage.to) and (self:isWeak(damage.to) or (self.player:getHp() + self:getAllPeachNum(player) > 1 and damage.damage == 1) or (self:needToThrowArmor() and damage.damage == 1)) then
		to_discard = dimeng_discard(self, 1, cards)
	end
	if #to_discard > 0 and sgs.Sanguosha:getCard(to_discard[1]):isKindOf("Peach") then
		return {}
	end
	return to_discard
end

sgs.ai_skill_cardask["@xunxing"] = function(self, data, pattern, target)
	local damage = data:toDamage()
	if not damage then
		return "."
	end
	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	if self:isEnemy(damage.from) and self:isFriend(damage.to) and not self:needToLoseHp(damage.to) and (self:isWeak(damage.to) or (self.player:getHp() + self:getAllPeachNum(player) > 1 and damage.damage == 1) or (self:needToThrowArmor() and damage.damage == 1)) then
		to_discard = dimeng_discard(self, 1, cards)
	end
	if #to_discard == 0 or sgs.Sanguosha:getCard(to_discard[1]):isKindOf("Peach") then
		return "."
	end
	return to_discard[1] or "."
end





--嘲讽
sgs.ai_chaofeng.jiyi_changbeibuxie = -1

--------------------------------------------------
--反理
--------------------------------------------------

local fanli_skill = {}
fanli_skill.name = "fanli"
table.insert(sgs.ai_skills, fanli_skill)
fanli_skill.getTurnUseCard = function(self, inclusive)
	local obj_name
	for _, mark in sgs.list(self.player:getMarkNames()) do
		if string.startsWith(mark, "&fanli+") and self.player:getMark(mark) > 0 then
			obj_name = string.sub(mark, 8, -1)
			break
		end
	end
	if self.player:getMark("fanli_used") == 0 and self.player:getPhase() == sgs.Player_Play and obj_name then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		local trans_card
		self:sortByKeepValue(cards)
	
		local virtual_card = sgs.Sanguosha:cloneCard(obj_name)
		local class_name = virtual_card:getClassName()
		for _, card in ipairs(cards) do
			if not card:hasFlag("using") and (self:getKeepValue(card) <= 5 and self:getUseValue(card) < sgs.ai_use_value[class_name]) or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, virtual_card) > 0 then
				trans_card = card
				break
			end
		end
		virtual_card:deleteLater()

		if trans_card then
			local suit = trans_card:getSuitString()
			local number = trans_card:getNumberString()
			local card_id = trans_card:getEffectiveId()
			local card_str = ("%s:fanli[%s:%s]=%d"):format(obj_name, suit, number, card_id)
			local new_card = sgs.Card_Parse(card_str)
	
			assert(new_card)
			return new_card
		end
	end
end

sgs.ai_view_as.fanli = function(card, player, card_place)
	local obj_name
	for _, mark in sgs.list(player:getMarkNames()) do
		if string.startsWith(mark, "&fanli+") and player:getMark(mark) > 0 then
			obj_name = string.sub(mark, 8, -1)
			break
		end
	end
	if player:getMark("fanli_used") == 0 and player:getPhase() == sgs.Player_Play and obj_name then
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		if card_place ~= sgs.Player_PlaceSpecial and not card:hasFlag("using") then
			return ("%s:fanli[%s:%s]=%d"):format(obj_name, suit, number, card_id)
		end
	end
end

sgs.ai_need_damaged.fanli = function (self, attacker, player)
	local obj_name
	for _, mark in sgs.list(player:getMarkNames()) do
		if string.startsWith(mark, "&fanli+") and player:getMark(mark) > 0 then
			obj_name = string.sub(mark, 8, -1)
			break
		end
	end
	if not obj_name and player:getHp() > 1 and not (player:getHp() == 2 and player:hasSkill("chanyuan")) then
		return true
	end
	return false
end

--------------------------------------------------
--势惜
--------------------------------------------------

sgs.ai_need_damaged.shixi = function (self, attacker, player)
	local kingdoms = {}
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:isWounded() and not table.contains(kingdoms, p:getKingdom()) then
			table.insert(kingdoms, p:getKingdom())
		end
	end
	local X = #kingdoms
	if X > 1 and player:getLostHp() < 2 then
		return true
	end
end





--嘲讽
sgs.ai_chaofeng.lige_jiachuantianyi = -1	--这么弱还有个小卖血真没必要打，先把她队友清完了她就白了

--------------------------------------------------
--假讯
--------------------------------------------------

sgs.ai_skill_playerchosen.jiaxun = function(self, targetlist)
	local data = self.player:getTag("jiaxun_data")
	local damage = data:toDamage()
	
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "defense")
	
	if self.room:getLord() and self.room:getMode() ~= "04_tt" and self.room:getMode() ~= "04_if" and self.room:getMode() ~= "couple" then	--让主杀忠
		if damage.to:getRole() == "loyalist" and damage.damage >= damage.to:getHp() + self:getAllPeachNum(damage.to) then
			if self:isEnemy(self.room:getLord()) then
				return self.room:getLord()
			elseif self:isFriend(self.room:getLord()) then		--若主公为友方，则不选择该友方
				table.removeOne(targetlist, self.room:getLord())
			end
		end
	end
	if self.room:getMode() == "couple" then		--CP模式嫁祸
		if damage.damage >= damage.to:getHp() + self:getAllPeachNum(damage.to) then
			local cp = damage.to:getTag("spouse"):toPlayer()
			if cp and cp:isAlive() and self:isEnemy(cp) then
				return cp
			elseif self:isFriend(cp) then	--自己要死不要嫁祸给队友
				return nil
			end
		end
	end
	
	if damage.to:hasSkills("chushou") then		--受伤者有能被利用的反伤类锁定技，直接转嫁敌人（不转嫁给利用者本身），没有敌人则不选择角色（不要坑你队友）
		for _, p in ipairs(targetlist) do
			if self:isEnemy(p) and p:objectName() ~= damage.to:objectName() then
				return p
			end
		end
		return nil
	end
	
	local targets = {}	--多层优先级处理
	local dmg_before = self:getDamageAdjustment(damage.from, damage.to, damage.card, damage.damage, damage.nature)
	for _, p in ipairs(targetlist) do
		local dmg = self:getDamageAdjustment(p, damage.to, damage.card, damage.damage, damage.nature)
		
		if self:isFriend(damage.to) then	--受伤者为队友：最优先减伤，然后优先给需要造成伤害的队友，其次是能摸牌的普通队友
			if self:isFriend(p) then
				local priority = 2
				if dmg < dmg_before then		--能减伤则优先级提升两级
					priority = 0
				end
				if not targets[1+priority] and self:needDamage(p) and dmg > 0 then
					targets[1+priority] = p
				end
				if not targets[2+priority] and self:canDraw(p) then
					targets[2+priority] = p
				end
			end
		elseif self:isEnemy(damage.to) then	--受伤者为敌人：优先选能加伤的角色，是队友更优先；不能加伤则按友方思路选
			if dmg > dmg_before then
				if not targets[1] and self:isFriend(p) then
					targets[1] = p
				end
				if not targets[2] then
					targets[2] = p
				end
			elseif dmg == dmg_before and self:isFriend(p) then
				if not targets[3] and self:canDraw(p) then
					targets[3] = p
				end
				if not targets[4] and self:needDamage(p) and dmg > 0 then
					targets[4] = p
				end
			elseif self:isFriend(p) then
				if not targets[5] and self:canDraw(p) then
					targets[5] = p
				end
			end
		else								--受伤者与你中立：按友方思路选，但不管伤害
			if self:isFriend(p) then
				if not targets[1] and self:needDamage(p) and dmg > 0 then
					targets[1] = p
				end
				if not targets[2] and self:canDraw(p) then
					targets[2] = p
				end
			end
		end
	end
	
	return targets[1] or targets[2] or targets[3] or targets[4] or targets[5] or nil
end

sgs.ai_playerchosen_intention.jiaxun = function(self, from, to)
	local intention = -10
	if to:isLord() and self:isEnemy(from, to) and self.room:getMode() ~= "04_tt" then
		intention = 0
	end
	sgs.updateIntention(from, to, intention)
end

--------------------------------------------------
--争欲
--------------------------------------------------

sgs.ai_skill_cardask["@zhengyu_ask"] = function(self, data, pattern, target)
	local current = self.room:getCurrent()
	local max_card = self:getMaxCard(self.player)
	
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	local useless_card = cards[1]
	
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:setSkillName("_zhengyu")
	
	--local isSafe = not self:slashIsEffective(duel, self.player, current) or self:slashProhibit(duel, self.player, current)
	local isSafe = not self:hasTrickEffective(duel, to, from)
	if not isSafe and self.player:getHandcardNum() >= 3 and (getCardsNum("Jink", self.player, self.player) > 0 or self.player:getHp() >= 4) then
		isSafe = true
	end
	
	if self:isEnemy(current) and self.player:canUse(duel, current) and self:hasTrickEffective(duel, to, from) then
		duel:deleteLater()
		if self:isWeak(current) and current:getHandcardNum() == 1 and (not self:isWeak() or max_card:getNumber() > 10 or isSafe) then
			if max_card:getNumber() >= 10 then
				return max_card:getId()
			elseif not useless_card:isKindOf("Peach") then
				return useless_card:getId()
			end
		elseif max_card:getNumber() > 10 then
			if self:isWeak() and (max_card:getNumber() >= 12 or isSafe) then
				return max_card:getId()
			else
				return max_card:getId()
			end
		elseif isSafe and not (useless_card:isKindOf("Peach") or useless_card:isKindOf("Jink") or useless_card:isKindOf("Nullification")) then
			return useless_card:getId()
		end
	end
	duel:deleteLater()
	return "."
end

sgs.ai_cardneed.zhengyu = function(to, card, self)
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	end
end




--嘲讽
sgs.ai_chaofeng.tongguhesha_cpmode = -1

--------------------------------------------------
--巧任
--------------------------------------------------

sgs.ai_skill_use["@@qiaoren"] = function(self, prompt)
	if self.player:isKongcheng() then return "" end
	for _,p1 in sgs.qlist(self.room:getAlivePlayers()) do
		if not p1:getEquips():isEmpty() then
			local p2 = self.player
			--judgement_start--这部分与下面相同，目的是优先给自己
			local cards = sgs.QList2Table(p1:getEquips())
			local can_move = false
			for _, card in ipairs(cards) do
				local equip = card:getRealCard():toEquipCard()
				local equip_index = equip:location()
				if p2:getEquip(equip_index) == nil and p2:hasEquipArea(equip_index) then
					can_move = true
					break
				end
			end
			if can_move then
				if p1:objectName() ~= p2:objectName() and self:isFriend(p2) and (not self:isFriend(p1) or (self:isWeak(p2) and not self:isWeak(p1) or (self:needToThrowArmor(p1) and p1:getArmor()))) then
					local handcards = sgs.QList2Table(self.player:getCards("h"))
					self:sortByKeepValue(handcards)
					return "#qiaoren:"..handcards[1]:getEffectiveId()..":->"..p1:objectName().."+"..p2:objectName()
				end
			end
			--judgement_end--
			for _,p2 in sgs.qlist(self.room:getOtherPlayers(p1)) do
				--judgement_start--
				local cards = sgs.QList2Table(p1:getEquips())
				local can_move = false
				for _, card in ipairs(cards) do
					local equip = card:getRealCard():toEquipCard()
					local equip_index = equip:location()
					if p2:getEquip(equip_index) == nil and p2:hasEquipArea(equip_index) then
						can_move = true
						break
					end
				end
				if can_move then
					if p1:objectName() ~= p2:objectName() and self:isFriend(p2) and (not self:isFriend(p1) or (self:isWeak(p2) and not self:isWeak(p1) or (self:needToThrowArmor(p1) and p1:getArmor()))) then
						local handcards = sgs.QList2Table(self.player:getCards("h"))
						self:sortByKeepValue(handcards)
						return "#qiaoren:"..handcards[1]:getEffectiveId()..":->"..p1:objectName().."+"..p2:objectName()
					end
				end
				--judgement_end--
			end
		end
	end
end

sgs.ai_need_damaged.qiaoren = function (self, attacker, player)
	if not player:isKongcheng() and not self:isWeak(player) then
		local target = self:findPlayerToDiscard("ej", true, false, self.room:getAlivePlayers(), false, player)
		if target then
			return true
		end
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.xiaorou_cpmode = 1

--------------------------------------------------
--卸载
--------------------------------------------------

local xiezai_skill = {}
xiezai_skill.name = "xiezai"
table.insert(sgs.ai_skills, xiezai_skill)
xiezai_skill.getTurnUseCard = function(self,inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	local black_card

	self:sortByUseValue(cards,true)

	local has_weapon = false

	for _,card in ipairs(cards)  do
		if card:isKindOf("Weapon") and card:isBlack() then has_weapon = true end
	end

	for _,card in ipairs(cards)  do
		if not card:isKindOf("BasicCard") and ((self:getUseValue(card) < sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow() > 0) then
			local shouldUse = true

			if card:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(card) and not self:needToThrowArmor() then shouldUse = false
				end
			end

			if card:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then shouldUse = false
				end
			end

			if card:isKindOf("Slash") then
				local dummy_use = {isDummy = true}
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.Dismantlement and card:isKindOf("TrickCard") then
				local dummy_use = {isDummy = true}
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				black_card = card
				break
			end

		end
	end

	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("dismantlement:xiezai[%s:%s]=%d"):format(suit, number, card_id)
		local dismantlement = sgs.Card_Parse(card_str)

		assert(dismantlement)

		return dismantlement
	end
end

function sgs.ai_cardneed.xiezai(to, card)
	return not card:isKindOf("BasicCard")
end

--------------------------------------------------
--柔辉
--------------------------------------------------

sgs.ai_skill_use["@@rouhui"] = function(self, prompt)
    local targets = {}
	local targets_list = sgs.SPlayerList()
    table.insert(targets, self.player:objectName())
	targets_list:append(self.player)
	self:sort(self.friends_noself, "defense")
    for i = 1, #self.friends_noself, 1 do
		local friend = self.friends_noself[i]
        if targets_list:length() < self.player:getMark("&rouhui!") and not (friend:isKongcheng() and self:needKongcheng(friend)) and not hasManjuanEffect(friend) and self.player:canEffect(friend, "rouhui") then
            table.insert(targets, friend:objectName())
			targets_list:append(friend)
        end
    end
    return "#rouhui:.:->"..table.concat(targets, "+")
end

sgs.ai_cardneed.rouhui = function(to, card, self)
	return card:isKindOf("EquipCard")
end




--嘲讽
sgs.ai_chaofeng.xitu_duoshelingtu = -1

--------------------------------------------------
--应激
--------------------------------------------------

sgs.ai_skill_invoke.yingji = function(self, data)
	local objname = string.sub(data:toString(), 8, -1)	--截取choice:后面的部分(即player:objectName())
	local to = findPlayerByObjName(self.room, objname)
	if to then
		if self:isFriend(to) and (not to:faceUp() or (self:getOverflow(to) > 2 and to:getPhase() == sgs.Player_Play)) then
			return true
		elseif self:isEnemy(to) and to:faceUp() and (to:getPhase() == sgs.Player_NotActive or self:getOverflow(to) <= 0 or not self:canDraw(to, self.player)) then
			return true
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.yingji = function(self, player, promptlist)	--yun
	local to = findPlayerByFlag(self.room, "yingji_AI")
	if to then
		local agree = 1
		if promptlist[#promptlist] == "yes" then
			agree = 1
		elseif promptlist[#promptlist] == "no" then
			agree = -1
		end
		
		local value = 0
		if not to:faceUp() then
			value = -10
		--elseif self:getOverflow(to) >= 2 then
		--	value = 0
		elseif not self:canDraw(to, player) or to:getPhase() == sgs.Player_NotActive then
			value = 10
		end
		
		sgs.updateIntention(player, to, value*agree)
	end
end

sgs.ai_need_damaged.yingji = function (self, attacker, player)
	if (not self:isWeak(player) or self:getAllPeachNum(player) > 0) and attacker then
		if self:isFriend(attacker, player) and (not attacker:faceUp() or (self:getOverflow(attacker) > 2 and attacker:getPhase() == sgs.Player_Play)) then
			return true
		elseif self:isEnemy(attacker, player) and attacker:faceUp() and (attacker:getPhase() == sgs.Player_NotActive or self:getOverflow(attacker) <= 1 or not self:canDraw(attacker, player)) then
			return true
		end
	end
	return false
end

--------------------------------------------------
--附身
--------------------------------------------------

sgs.ai_skill_invoke.fushen = function(self, data)
	if #self.enemies > 0 and self:getOverflow() <= 1 then
		return true
	end
end

sgs.ai_skill_playerchosen.fushen = function(self, targetlist)
	local first, second, third
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "handcard")
	for _, p in ipairs(targetlist) do
		if not third then
			third = p
		end
		if not (first and second) and self:isEnemy(p) and not self:willSkipDrawPhase(p) and not self:willSkipPlayPhase(p) then
			if not second then
				second = p
			end
			if not first and p:hasSkills("zhuoshi|xiange|yinyou|jinzhou|quanneng|quanneng_xiaonai|jieshuo|diyin|manyuan|shuoyi|qianchang|yuejian_akane|zhonggong") then	--辅助杀手已上线，有内鬼！！
				first = p
			end
		end
		if first and second and third then
			break
		end
	end
	return first or second or third or nil
end

sgs.ai_playerchosen_intention.fushen = function(self, from, to)
	local intention = 10
	sgs.updateIntention(from, to, intention)
end




--嘲讽
sgs.ai_chaofeng.linglaiguang_shengsixiangyi = 3

--------------------------------------------------
--神伴
--------------------------------------------------

local shenban_skill={}
shenban_skill.name="shenban"
table.insert(sgs.ai_skills,shenban_skill)
shenban_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#shenban") < 1 and not self.player:isKongcheng() then
		return sgs.Card_Parse("#shenban:.:")
	end
end
sgs.ai_skill_use_func["#shenban"] = function(card, use, self)
	local cards = {}
	for _,cd in sgs.qlist(self.player:getHandcards()) do
		if cd:isRed() then
			table.insert(cards, cd)
		end
	end
	
	local ids = dimeng_discard(self, 1, cards)
	if #ids == 0 then
		return
	end
	
	self:sort(self.friends, "handcard")
	for _, friend in ipairs(self.friends) do
		if friend:getMark("&shenban") == 0 and SkillCanTarget(friend, self.player, "shenban") and self.player:canEffect(friend, "shenban") then
			if use.to then
				use.to:append(friend)
			end
			card_str = "#shenban:"..ids[1]..":->"..friend:objectName()
			use.card = sgs.Card_Parse(card_str)
			break
		end 
	end
end

--sgs.ai_use_priority["shenban"] = 8
sgs.ai_use_priority["shenban"] = 0

sgs.ai_card_intention.shenban = -10

sgs.ai_cardneed.shenban = function(to, card, self)
	return card:isRed()
end

--------------------------------------------------
--逝随
--------------------------------------------------

sgs.ai_skill_invoke.shisui = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if self:getAllPeachNum(target, true) == 0 then
			return true
		end
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.hana_menglufanhua = -1

--------------------------------------------------
--芸芸
--------------------------------------------------

sgs.ai_skill_cardask["@yunyun_recast"] = function(self, data, pattern, target)
	if not self:canDraw() then
		return "."
	end
	local card = data:toCardUse().card or data:toCardResponse().m_card
	if card and card:isKindOf("EquipCard") then		--使用装备时，优先重铸被顶掉的装备
		local equip_index = card:getRealCard():toEquipCard():location()
		if self.player:getEquip(equip_index) ~= nil then
			return self.player:getEquip(equip_index):getEffectiveId()
		end
	end
	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	to_discard = dimeng_discard(self, 1, cards, 3)
	if #to_discard > 0 and sgs.Sanguosha:getCard(to_discard[1]):isKindOf("Peach") then
		return "."
	end
	return to_discard[1] or "."
end

--------------------------------------------------
--欣荣
--------------------------------------------------

sgs.ai_skill_invoke.xinrong = function(self, data)
	return true
end





--嘲讽
sgs.ai_chaofeng.zhenliyuanhuan_yishijiedezhipeizhe = -2

--------------------------------------------------
--极理
--------------------------------------------------

sgs.ai_skill_choice.jili_magi = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if table.contains(items, "jili_magi_dec1") and self:isWeak() then
			return "jili_magi_dec1"
		end
		if table.contains(items, "jili_magi_inc1") then
			return "jili_magi_inc1"
		end
		if table.contains(items, "jili_magi_dec1") then
			return "jili_magi_dec1"
		end
	end
	return "cancel"
end

sgs.ai_need_damaged.jili_magi = function(self, attacker, player)
	if not self:isWeak(player) and player:getMark("jili_magi_inc1") == 0 then
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.linde_yijingqingke = 1

--------------------------------------------------
--灵润
--------------------------------------------------

sgs.ai_skill_invoke.lingrun = function(self, data)
	return self:canDraw() and (not self.player:hasSkills("juling") or self:isWeak())
end




--嘲讽
sgs.ai_chaofeng.loryi = 1

--------------------------------------------------
--泥嚎
--------------------------------------------------

sgs.ai_skill_cardask["@nihao_give"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards, self:isFriend(self.room:getCurrent()))
	for _, card in ipairs(cards) do
		return "$" .. card:getEffectiveId()
	end
	return "$" .. cards[1]:getEffectiveId()
end





--嘲讽
sgs.ai_chaofeng.lupu_tiancaitanxianjia = 0

--------------------------------------------------
--考徵
--------------------------------------------------

local kaozhi_skill = {}
kaozhi_skill.name = "kaozhi"
table.insert(sgs.ai_skills, kaozhi_skill)
kaozhi_skill.getTurnUseCard = function(self, inclusive)
	local obj_name
	for _, mark in sgs.list(self.player:getMarkNames()) do
		if string.startsWith(mark, "&kaozhi+") and self.player:getMark(mark) > 0 then
			obj_name = string.sub(mark, 9, -6)
			break
		end
	end
	if self.player:getMark("kaozhi_used") < 1 and self.player:getPhase() == sgs.Player_Play and obj_name then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		local trans_card
		self:sortByKeepValue(cards)
	
		local virtual_card = sgs.Sanguosha:cloneCard(obj_name)
		local class_name = virtual_card:getClassName()
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Spade and not card:hasFlag("using") and ((self:getKeepValue(card) <= 5+5 and self:getUseValue(card) < sgs.ai_use_value[class_name]) or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, virtual_card) > 0) then
				trans_card = card
				break
			end
		end
		virtual_card:deleteLater()

		if trans_card then
			local suit = trans_card:getSuitString()
			local number = trans_card:getNumberString()
			local card_id = trans_card:getEffectiveId()
			local card_str = ("%s:kaozhi[%s:%s]=%d"):format(obj_name, suit, number, card_id)
			local new_card = sgs.Card_Parse(card_str)
	
			assert(new_card)
			return new_card
		end
	end
end

sgs.ai_view_as.kaozhi = function(card, player, card_place)
	local obj_name
	for _, mark in sgs.list(player:getMarkNames()) do
		if string.startsWith(mark, "&kaozhi+") and player:getMark(mark) > 0 then
			obj_name = string.sub(mark, 9, -6)
			break
		end
	end
	if player:getMark("kaozhi_used") < 1 and player:getPhase() == sgs.Player_Play and obj_name then
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		if card_place ~= sgs.Player_PlaceSpecial and card:getSuit() == sgs.Card_Spade and not card:hasFlag("using") then
			return ("%s:kaozhi[%s:%s]=%d"):format(obj_name, suit, number, card_id)
		end
	end
end

sgs.ai_cardneed.kaozhi = function(to, card, self)
	return card:getSuit() == sgs.Card_Spade
end

sgs.ai_skill_askforag["kaozhi"] = function(self, card_ids)
	self:sortIdsByValue(card_ids, "use", false)
	return card_ids[1]
end

sgs.kaozhi_suit_value = {
	spade = 5,
}

--------------------------------------------------
--探宝
--------------------------------------------------

local tanbao_skill={}
tanbao_skill.name="tanbao"
table.insert(sgs.ai_skills,tanbao_skill)
tanbao_skill.getTurnUseCard = function(self, inclusive)
	local has_treasure = false
	for _,id in sgs.qlist(self.room:getDrawPile()) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Treasure") then
			has_treasure = true
		end
		if has_treasure then
			break
		end
	end
	for _,id in sgs.qlist(self.room:getDiscardPile()) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Treasure") then
			has_treasure = true
		end
		if has_treasure then
			break
		end
	end
	if self.player:usedTimes("#tanbao") < 1 and has_treasure then
		return sgs.Card_Parse("#tanbao:.:")
	end
end
sgs.ai_skill_use_func["#tanbao"] = function(card, use, self)
	local equips = {}
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("EquipCard") and not self.player:isJilei(card) then
			table.insert(equips, card)
		end
	end
	if #equips > 0 then
		local ids = dimeng_discard(self, 1, equips, 2)
		if #ids > 0 then
			card_str = "#tanbao:"..ids[1]..":"
			use.card = sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_priority["tanbao"] = sgs.ai_use_priority.SilverLion - 0.01





--嘲讽
sgs.ai_chaofeng.wuqian_daweiba = 0

--------------------------------------------------
--奇虑
--------------------------------------------------

sgs.ai_skill_use["@@qilv"] = function(self,prompt)
	self:updatePlayers()
	self:sort(self.enemies, "defense")

	--if self:needBear() then return "." end
	for _,enemy in ipairs(self.enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash")
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

		if not self.player:canSlash(enemy, slash, false) or not self.player:inMyAttackRange(enemy) or self:slashProhibit(nil, enemy) then
			slash:deleteLater()
		elseif eff then
			slash:deleteLater()
			return "#qilv:.:->"..enemy:objectName()
		else
			slash:deleteLater()
			return "."
		end
	end
	return "."
end

sgs.ai_cardneed.zhuoshi = function(to, card, self)
	return card:isKindOf("TrickCard")
end

--------------------------------------------------
--手杀乱击
--------------------------------------------------

local mobileluanji_skill = {}
mobileluanji_skill.name = "mobileluanji"
table.insert(sgs.ai_skills, mobileluanji_skill)
mobileluanji_skill.getTurnUseCard = function(self)
	--local archery = sgs.Sanguosha:cloneCard("archery_attack")
	local first_found, second_found = false, false
	local first_card, second_card
	local suits = self.player:property("mobileluanji_suitstring"):toString():split("+")
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local useAll = false
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and not enemy:hasArmorEffect("Vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
				and self:isWeak(enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
			if useAll then fvalueCard = isCard("ArcheryAttack", fcard, self.player) end
			if not table.contains(suits, fcard:getSuitString()) and not fvalueCard then
				first_card = fcard
				first_found = true
				local second_card_same, second_card_normal
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard --[[and scard:getSuit() == first_card:getSuit()]] and not table.contains(suits, scard:getSuitString())
						and not svalueCard then

						local card_str = ("archery_attack:mobileluanji[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = { isDummy = true }
						self:useTrickCard(archeryattack, dummy_use)
						if dummy_use.card then
							second_card_normal = scard
							if scard:getSuit() == first_card:getSuit() then
								second_card_same = scard
								break
							end
							
							if not second_card_normal then
								second_card_normal = scard
							end
						end
					end
				end
				second_card = second_card_same or second_card_normal
				if second_card then
					second_found = true
					break
				end
			end
		end
	end

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("archery_attack:mobileluanji[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
end

--------------------------------------------------
--驱动（旧稿）
--------------------------------------------------

sgs.ai_skill_invoke.qudong = function(self, data)
	local current = self.room:getCurrent()
	return not self:isWeak(current) or not self:canDraw(current, self.player)
end




--嘲讽
sgs.ai_chaofeng.haiyuexun_yangyingfuguang = 0

--------------------------------------------------
--浮光
--我懒了，直接魔改的说盟的ai。开摆！
--------------------------------------------------

local fuguang_skill = {}
fuguang_skill.name= "fuguang"
table.insert(sgs.ai_skills,fuguang_skill)
fuguang_skill.getTurnUseCard=function(self)
	if self:needBear() then return end
	if not self.player:hasUsed("#fuguang") and not self.player:isKongcheng() then
		return sgs.Card_Parse("#fuguang:.:")
	end
end

sgs.ai_skill_use_func["#fuguang"] = function(card, use, self)
	local cards = sgs.CardList()
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player, cards)
	
	if max_card then
		local second_target
		self:sort(self.friends_noself, "defense")
		for _, friend in ipairs(self.friends_noself) do
			if not friend:isKongcheng() and self.player:canEffect(friend, "fuguang") then
				if self:needKongcheng(friend) and friend:getHandcardNum() == 1 then
					use.card = sgs.Card_Parse("#fuguang:" .. max_card:getId() .. ":->" .. friend:objectName())
					if use.to then
						use.to:append(friend)
					end
					return
				end
				if (not self:willUse(self.player, max_card) and max_card:isBlack() and max_card:getNumber() > 6) and friend:getHandcardNum() >= 3 and not self:isWeak(friend) and not self:isWeak() and self:getOverflow() > 0 then
					second_target = friend
				end
			end
		end
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if not (self:needKongcheng(enemy) and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self.player:canEffect(enemy, "fuguang") then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if max_card:getNumber() > enemy_max_point then
					use.card = sgs.Card_Parse("#fuguang:" .. max_card:getId() .. ":->" .. enemy:objectName())
					if use.to then
						use.to:append(enemy)
					end
					return
				end
				
				if (max_card:getNumber() >= 9 and enemy:getHandcardNum() <= 3) or max_card:getNumber() >= 12 or (self:isWeak(enemy) and enemy:getHandcardNum() <= 2) then
					second_target = enemy
				end
			end
		end
		if second_target then
			use.card = sgs.Card_Parse("#fuguang:" .. max_card:getId() .. ":->" .. second_target:objectName())
			if use.to then
				use.to:append(second_target)
			end
			return
		end
	end
end

sgs.ai_use_value.fuguang = 2.5
sgs.ai_use_priority.fuguang = 9

function sgs.ai_skill_pindian.fuguang(minusecard, self, requestor)
	if requestor:getHandcardNum() == 1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return cards[1]
	end
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end

sgs.ai_skill_use["@@fuguang!"] = function(self, prompt, method)
	self:updatePlayers()
	
	local target_card = sgs.Sanguosha:getCard(self.player:getMark("fuguang_id")-1)
	if target_card then
		if target_card:targetFixed() then
			return target_card:toString()
		else
			if target_card:isKindOf("Slash") then	--yun
				local to = self:findPlayerToSlash(true, target_card, nil, true)		--距离限制、卡牌、角色限制、必须选择
				return target_card:toString() .. "->" .. to:objectName()
			end
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(target_card, dummyuse)
			local targets = {}
			if not dummyuse.to:isEmpty() then
				for _, p in sgs.qlist(dummyuse.to) do
					table.insert(targets, p:objectName())
				end
				return target_card:toString() .. "->" .. table.concat(targets, "+")
			else		--强制选择随机目标
				local targets_list = sgs.PlayerList()
				for _, target in sgs.qlist(self.room:getAlivePlayers()) do
					targets_list:append(target)
				end
				local targets = {}
				for _,p in sgs.qlist(self.room:getAlivePlayers()) do
					if target_card:targetFilter(targets_list, p, self.player) and not sgs.Self:isProhibited(p, target_card) then
						table.insert(targets, p:objectName())
					end
				end
				if #targets > 0 then
					return target_card:toString() .. "->" .. targets[math.random(1,#targets)]
				end
			end
		end
	end
	return "."
end

sgs.ai_cardneed.fuguang = function(to, card, self)	--需要大点至少一张
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	end
end

--------------------------------------------------
--潜影
--------------------------------------------------

sgs.ai_skill_invoke.qianying = function(self, data)
	if not self:canDraw() then return false end		--自己不能摸牌，不发动
	local pindian = data:toPindian()
	local player, other
	local player_card, other_card
	local player_number, other_number
	if self.player:objectName() == pindian.from:objectName() then
		player = pindian.from
		player_card = pindian.from_card
		player_number = pindian.from_number
		other = pindian.to
		other_card = pindian.to_card
		other_number = pindian.to_number
	else
		other = pindian.from
		other_card = pindian.from_card
		other_number = pindian.from_number
		player = pindian.to
		player_card = pindian.to_card
		player_number = pindian.to_number
	end
	if self:isFriend(other, player) then	--和友方拼点，发动
		return true
	end
	if player_number <= other_number then	--本来就没赢，发动
		return true
	end
	if player_number - 6 > other_number then	--减了还是赢，发动
		return true
	end
	if pindian.reason == "fuguang" then		--浮光拼点的特殊处理
		if self:getUseValue(player_card) < 6 or not self:willUse(player, player_card) then	--过牌前提：我方的牌没有使用价值
			if not other:canUse(other_card) then	--对面赢了也用不了，发动
				return true
			elseif other_card:isKindOf("EquipCard") and self:getSameEquip(other_card, other) and not other:hasSkills(sgs.lose_equip_skill) then	--是重复装备，发动
				return true
			elseif other_card:isKindOf("Analeptic") and other:getPhase() == sgs.Player_NotActive then	--是回合外的酒，发动
				return true
			end
		end
	end
	return false
end

sgs.ai_cardneed.qianying = function(to, card, self)	--需要黑色点数>6的牌至少一张
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isBlack() and c:getNumber() > 6 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:isBlack() and card:getNumber() > 6
	end
end




--嘲讽
sgs.ai_chaofeng.bison_cimushouzhongxian = 0

--------------------------------------------------
--鼠化
--------------------------------------------------

sgs.ai_skill_use["@@shuhua"] = function(self, prompt)
    local targets = {}
	self:sort(self.enemies, "defense")
    for i = 1, #self.enemies, 1 do
		local enemy = self.enemies[i]
		if #targets < self.player:getMark("&shuhua!") and SkillCanTarget(enemy, self.player, "shuhua") and self.player:canEffect(enemy, "shuhua") and not table.contains(targets, enemy:objectName()) then
			if enemy:getKingdom() ~= "bisonpro" then
				table.insert(targets, enemy:objectName())
			end
		end
    end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if #targets < self.player:getMark("&shuhua!") and SkillCanTarget(p, self.player, "shuhua") and self.player:canEffect(p, "shuhua") and not table.contains(targets, p:objectName()) then
			if p:getKingdom() ~= "bisonpro" then
				table.insert(targets, p:objectName())
			end
		end
	end
	self:sort(self.friends, "defense")
    for i = 1, #self.friends, 1 do
		local friend = self.friends[i]
        if #targets < self.player:getMark("&shuhua!") and SkillCanTarget(friend, self.player, "shuhua") and self.player:canEffect(friend, "shuhua") and not table.contains(targets, friend:objectName()) then
			if self:canDraw(friend) then
				table.insert(targets, friend:objectName())
			end
        end
    end
    return "#shuhua:.:->"..table.concat(targets, "+")
end

--------------------------------------------------
--妙评
--------------------------------------------------

sgs.ai_skill_playerchosen.miaoping = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "defense")
	
	local first, second, third
	
	for _, p in ipairs(targetlist) do
		if self.player:getChangeSkillState("miaoping") <= 1 then	--妙评①
			if self:isEnemy(p) then
				if not first and self:getOverflow(p) <= -2 then		--最优先给加了上限也不用弃牌的敌人
					first = p
				end
				if not second and p:getHandcardNum() >= 4 then	--其次是牌多于4张的敌人
					second = p
				end
				if not third then	--随便给一个敌人，为了转换到②，毕竟②太强了
					third = p
				end
			elseif self:isFriend(p) then
				if not first and self:getOverflow(p) >= 0 and p:hasSkills("yinyou") then	--第一优先级，给牌将溢出且本来就不用杀的队友
					first = p
				end
				if not second and self:getOverflow(p) >= 0 and self:isWeak(p) then			--第二优先级，给牌将溢出且濒危的队友
					second = p
				end
			end
		else														--妙评②
			if self:isEnemy(p) and (not self:willSkipDrawPhase(p) or not self:canDraw(p)) then
				if not first and self:getOverflow(p) >= 0 then
					first = p
				end
				if not second and self:getOverflow(p) + self:ImitateResult_DrawNCards(p, p:getVisibleSkillList(true)) >= 0 then
					second = p
				end
			elseif self:isFriend(p) and (self:willSkipDrawPhase(p) or (self:canDraw(p) and math.min(5, p:getMaxCards()) - p:getHandcardNum() > self:ImitateResult_DrawNCards(p, p:getVisibleSkillList(true)) and getCardsNum("Jink", p, self.player) > 0)) then
				if not third then
					third = p
				end
			end
		end
		if first and second and third then
			break
		end
	end
	return first or second or third
end

--------------------------------------------------
--鼠糖
--------------------------------------------------

sgs.ai_skill_playerchosen.shutang = function(self, targetlist)
	local targets = self:findPlayerToDraw(true, 1, 999)
	targetlist = sgs.QList2Table(targetlist)
	for _, target in ipairs(targets) do
		for _, p in ipairs(targetlist) do
			if p:objectName() == target:objectName() then
				return p
			end
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.shutang = function(self, from, to)
	local intention = -10
	sgs.updateIntention(from, to, intention)
end

--------------------------------------------------
--极道（交牌部分）
--------------------------------------------------

sgs.ai_skill_discard.jidao = function(self, discard_num, min_num, optional, include_equip)
	local toDis = {}
	local target = findPlayerByFlag(self.room, "jidao_receiver_AI")
	if target and self:isFriend(target) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(cards, false)
		for _, card in ipairs(cards) do
			if self:needCard(target, card) then		--新函数，返回某角色是否需要某张牌（根据cardneed）
				table.insert(toDis, card:getEffectiveId())
				return toDis
			end
		end
		table.insert(toDis, cards[1]:getEffectiveId())
		return toDis
	end
	return self:askForDiscard("", discard_num, min_num, optional, include_equip)
end




--嘲讽
sgs.ai_chaofeng.miaotianmiye_miaomiaoshenguan = -1

--------------------------------------------------
--域界
--------------------------------------------------

sgs.ai_skill_invoke.yujie = function(self, data)
	local _data = self.player:getTag("yujie_data_AI")
	local use = _data:toCardUse()
	--来源为友方，不发动
	if not use.from or use.from:isDead() or self:isFriend(use.from) then
		return false
	end
	--本来就无效，不发动
	if use.card:isKindOf("Slash") and not self:slashIsEffective(use.card, self.player, use.from, false, true) then	--新增最后一项代表无视技能
		return false
	end
	if use.card:isKindOf("TrickCard") and not self:hasTrickEffective(use.card, self.player, use.from, true) then	--新增最后一项代表无视技能
		return false
	end
	--是加成牌或需要因此牌而掉血，不发动
	local objname = use.card:objectName()
	if objname == "analeptic" or objname == "peach" or objname == "amazing_grace" or objname == "ex_nihilo" or objname == "god_salvation" then
		return false
	end
	if (objname == "slash" or objname == "fire_slash" or objname == "thunder_slash" or objname == "ice_slash" or objname == "archery_attack" or objname == "savage_assault" or objname == "fire_attack") and self:needToLoseHp() then
		return false
	end
	return true
end

sgs.ai_skill_cardask["@yujie_show"] = function(self, data, pattern, target)
	local from = data:toPlayer()
	if from and self:isFriend(from) then
		return "."
	end
	
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:hasFlag("yujie_flag") then
			return "$" .. card:getEffectiveId()
		end
	end
	
	return "."
end

--------------------------------------------------
--绝喵咒术！
--------------------------------------------------

local juemiaozhoushu_skill={}
juemiaozhoushu_skill.name="juemiaozhoushu"
table.insert(sgs.ai_skills,juemiaozhoushu_skill)
juemiaozhoushu_skill.getTurnUseCard=function(self,inclusive)
	if self.player:getMark("@juemiaozhoushu") > 0 then
		local profit = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:getHp() > self.player:getHp() and p:isWounded() then
				local basic_value = 2
				if self:isWeak(p) then
					basic_value = 2.5
				end
				if self:needToLoseHp(p, self.player, false, false, true) then	--needToLoseHp的第五个参数为真则考虑回血后情况
					basic_value = -2.5
				end
				if self:isFriend(p) then
					profit = profit + basic_value
				elseif self:isEnemy(p) then
					profit = profit - basic_value
				end
			elseif p:getHp() < self.player:getHp() then
				local basic_value = -2
				if self:needToLoseHp(p) or p:hasSkills(sgs.lose_hp_skills) then
					basic_value = 2
				end
				if p:getHp() == 1 then
					basic_value = basic_value - 2
				end
				if self:isFriend(p) then
					profit = profit + basic_value
				elseif self:isEnemy(p) then
					profit = profit - basic_value
				end
			end
		end
		if profit >= 2 or (profit > 0 and self:isWeak()) then
			return sgs.Card_Parse("#juemiaozhoushu:.:")
		end
	end
end

sgs.ai_skill_use_func["#juemiaozhoushu"] = function(card,use,self)
	if not use.isDummy then self:speak("juemiaozhoushu") end
	use.card = card
end

sgs.ai_use_priority["juemiaozhoushu"] = 8





--嘲讽
sgs.ai_chaofeng.jiyeqing_lingdaosuzhen = 1

--------------------------------------------------
--真刃
--------------------------------------------------

sgs.ai_skill_invoke.zhenren = function(self, data)
	for _, enemy in ipairs(self.enemies) do		--如果敌人有明牌会被针对的技能，就别用（如魔音）
		if enemy:hasSkills("newmoyin|qingleng|suoqiu") then
			return false
		end
	end
	
	if self.player:isKongcheng() and not self:needKongcheng() and self:canDraw() then
		return true
	end
	if self:willSkipPlayPhase() and self:getOverflow() >= -1 then
		return false
	end
	if self:getOverflow() > 0 and self:getCardsNum("Slash") > 0 and self.player:getWeapon() then
		return false
	end
	return self:canDraw()
end

--------------------------------------------------
--居合
--------------------------------------------------

sgs.ai_skill_cardask["@jvhe_use"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	local target = use.to:first()
	if target and (self:isFriend(target) or target:isKongcheng()) then
		return "."
	end
	
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, false)
	for _, card in ipairs(cards) do
		if card:hasFlag("jvhe_flag") then
			return "$" .. card:getEffectiveId()
		end
	end
	
	return "."
end

sgs.ai_cardneed.jvhe = function(to, card, self)
	return card:isKindOf("Slash") or card:isKindOf("Weapon")
end




--嘲讽
sgs.ai_chaofeng.zhugusheng_gushengsiyu = 1

--------------------------------------------------
--竹生
--------------------------------------------------

local zhusheng_skill = {}
zhusheng_skill.name = "zhusheng"
table.insert(sgs.ai_skills, zhusheng_skill)
zhusheng_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#zhusheng") >= 1 then return end
	return sgs.Card_Parse("#zhusheng:.:")
end
sgs.ai_skill_use_func["#zhusheng"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local cost_card
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Spade and self:getUseValue(card) < 6 then
			cost_card = card
			break
		end
	end
	
	local targets = sgs.SPlayerList()
	local first_targets = sgs.SPlayerList()
	for _, vic in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:canDiscard(vic, "he") and SkillCanTarget(vic, self.player, "zhusheng") and self.player:canEffect(vic, "zhusheng") then
			local not_overt_cardnum = 0
			for _,cd in sgs.qlist(vic:getHandcards()) do
				if not cd:isOvert() then
					not_overt_cardnum = not_overt_cardnum + 1
				end
			end
			targets:append(vic)
			if not_overt_cardnum < 2 then
				first_targets:append(vic)
			end
		end
	end
	
	local first, second
	if not first_targets:isEmpty() and not cost_card then	--有要弃的黑桃牌的话，不专门指定无法明置的角色
		first = self:findPlayerToDiscard("he", false, true, first_targets, false)
	end
	if not targets:isEmpty() and (cost_card or self:getOverflow() > 0 or self:needToThrowArmor() or self:needToThrowHandcard() or self:needKongcheng()) then
		second = self:findPlayerToDiscard("he", false, true, targets, false)
	end
	
	local target = first or second
	if target then
		local cost_id = -1
		if cost_card then
			cost_id = cost_card:getEffectiveId()
		else
			local to_discard = dimeng_discard(self, 1, cards, 2.5)
			if #to_discard > 0 then
				cost_id = to_discard[1]
			end
		end
		if cost_id and cost_id ~= -1 then
			if use.to then
				use.to:append(target)
			end
			card_str = "#zhusheng:"..cost_id..":->"..target:objectName()
			use.card = sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_value["zhusheng"] = 0.8 --卡牌使用价值
sgs.ai_use_priority["zhusheng"] = sgs.ai_use_priority.Dismantlement + 0.09 --卡牌使用优先级

sgs.ai_choicemade_filter.cardChosen["zhusheng"] = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_card_intention.zhusheng = function(self, card, from, tos)
    local to = tos[1]
    local intention = 10
    if self:needKongcheng(to) or self:needToThrowArmor(to) or self:needToThrowHandcard(to) then
        intention = 0
    end
    sgs.updateIntention(from, to, intention)
end

sgs.ai_skill_discard["zhusheng"] = function(self, discard_num, min_num, optional, include_equip)
	if self:isFriend(self.room:getCurrent()) and optional then
		return {}
	end
	local toDis = {}
	local not_overt_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:hasFlag("zhusheng_flag") and not table.contains(not_overt_cards, cd) then
			table.insert(not_overt_cards, cd)
		end
	end
	if #not_overt_cards < 2 then
		return {}
	end
	toDis = dimeng_discard(self, 2, not_overt_cards)
	if #toDis == 2 then
		return toDis
	end
	if not optional then
		toDis = {}
		table.insert(toDis, not_overt_cards[1])
		table.insert(toDis, not_overt_cards[2])
		return toDis
	end
	return {}
end

sgs.ai_cardneed.zhusheng = function(to, card, self)
	return card:getSuit() == sgs.Card_Spade
end

sgs.zhusheng_suit_value = {
	spade = 1,
}




--嘲讽
sgs.ai_chaofeng.qiliang_shixingeyin = 1

--------------------------------------------------
--鸣光
--------------------------------------------------

function sgs.ai_cardsview.mingguang(self, class_name, player)
	if class_name == "Slash" then
		return cardsView_spear(self, player, "mingguang")
	elseif class_name == "Jink" then
		local cards = player:getCards("he")
		cards = sgs.QList2Table(cards)
		local newcards = {}
		for _, card in ipairs(cards) do
			if not isCard("Jink", card, player) and not isCard("Peach", card, player) and not (isCard("ExNihilo", card, player) and player:getPhase() == sgs.Player_Play) then table.insert(newcards, card) end
		end
		if #newcards < 2 then return end
		sgs.ais[player:objectName()]:sortByKeepValue(newcards)
	
		local card_id1 = newcards[1]:getEffectiveId()
		local card_id2 = newcards[2]:getEffectiveId()
	
		local card_str = ("jink:%s[%s:%s]=%d+%d"):format("mingguang", "to_be_decided", 0, card_id1, card_id2)
		return card_str
	end
end

local mingguang_skill = {}
mingguang_skill.name = "mingguang"
table.insert(sgs.ai_skills, mingguang_skill)
mingguang_skill.getTurnUseCard = function(self, inclusive)
	return turnUse_spear(self, inclusive, "mingguang")
end





--嘲讽
sgs.ai_chaofeng.yayue_heisenlinyaolang = 1

--------------------------------------------------
--渴可
--------------------------------------------------

sgs.ai_skill_invoke.keke = function(self, data)
	return true
end





--嘲讽
sgs.ai_chaofeng.lidousha_xunxingzhuzhong = 0

--------------------------------------------------
--执夷
--------------------------------------------------

sgs.ai_skill_discard["zhiyi_lds"] = function(self, discard_num, min_num, optional, include_equip)	--yun
	local to_discard = {}
	local target = findPlayerByFlag(self.room, "zhiyi_lds_target_AI")
	local suit_counter = {0,0,0,0}
	local max_count = 0
	local max_suit = -1
	if target and not target:isNude() then
		if self:isEnemy(target) then
			for _,card in sgs.qlist(target:getCards("he")) do
				suit_counter[card:getSuit()+1] = suit_counter[card:getSuit()+1] + 1		--spade=0 club=1 heart=2 diamond=3
				if suit_counter[card:getSuit()+1] > max_count then
					max_count = suit_counter[card:getSuit()+1]
					max_suit = card:getSuit()
				end
			end
		end
	else
		return {}
	end
	
	if max_count > 0 and max_suit ~= -1 then
		local cards = {}
		for _,card in sgs.qlist(self.player:getCards("he")) do
			if card:getSuit() == max_suit then
				table.insert(cards, card)
			end
		end
		to_discard = dimeng_discard(self, 1, cards, max_count*3)
	end
	if #to_discard == 0 then
		for i = 0,3,1 do
			if i ~= max_suit and suit_counter[i+1] > 0 then
				local cards = {}
				for _,card in sgs.qlist(self.player:getCards("he")) do
					if card:getSuit() == i then
						table.insert(cards, card)
					end
				end
				to_discard = dimeng_discard(self, 1, cards, suit_counter[i+1]*3)
			end
			if #to_discard > 0 then
				break
			end
		end
	end
	return to_discard
end





--嘲讽
sgs.ai_chaofeng.xiaoqiancunyouyou_yaolingbaiyou = 1

--------------------------------------------------
--袭穴
--------------------------------------------------

sgs.ai_skill_invoke.xixue = function(self, data)
	return true
end

sgs.ai_cardneed.xixue = function(to, card)
	local xixue_candraw_suit = {"club", "spade", "diamond", "heart"}
	return card:getSuit() >= 0 and card:getSuit() <= 3 and to:getMark("&xixue+"..xixue_candraw_suit[card:getSuit()+1].."_char") > 0
end





--嘲讽
sgs.ai_chaofeng.xiaoqiancunyouyou_taoqishaonv = 1

--------------------------------------------------
--寻笑
--------------------------------------------------

local xunxiao_skill={}
xunxiao_skill.name="xunxiao"
table.insert(sgs.ai_skills,xunxiao_skill)
xunxiao_skill.getTurnUseCard=function(self)
	if (not self.player:hasUsed("#xunxiao")) and (not self.player:isNude()) then
		return sgs.Card_Parse("#xunxiao:.:")
	end
end

sgs.ai_skill_use_func["#xunxiao"] = function(card, use, self)
	local friend_target, enemy_target
	for _, friend in ipairs(self.friends_noself) do
		local players = self.room:getOtherPlayers(friend)
		local hasTarget = false
		for _,p in sgs.qlist(players) do
			if not self:isWeak(friend) and friend:getHandcardNum() >= p:getHandcardNum() and self:isEnemy(p) and p:objectName() ~= self.player:objectName() and p:canBePindianed() and self.player:canEffect(friend, "xunxiao") and self.player:canEffect(p, "xunxiao") then
				hasTarget = true
			end
		end
		if hasTarget then
			friend_target = friend
			break
		end
	end
	
	self:sort(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		local players = self.room:getOtherPlayers(enemy)
		local hasTarget = false
		local can_pindian = false
		for _,p in sgs.qlist(players) do
			if p:canBePindianed() and p:objectName() ~= self.player:objectName() and self.player:canEffect(enemy, "xunxiao") and self.player:canEffect(p, "xunxiao") then
				can_pindian = true
				if self:isEnemy(p) then
					hasTarget = true
				end
			end
		end
		if hasTarget and can_pindian then
			enemy_target = enemy
			break
		end
	end
	
	if not friend_target and not enemy_target then return end
	
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	
	for _, scard in ipairs(cards) do
		if scard:isBlack() and (self:getUseValue(scard) < 6 or (self:getOverflow() > 1 and self.room:getCardPlace(scard:getId()) == sgs.Player_PlaceHand)) then
			local target
			if scard:getNumber() >= 10 then
				target = friend_target or enemy_target
			else
				target = enemy_target or friend_target
			end
			if target then
				local card_str = "#xunxiao:"..scard:getId()..":->"..target:objectName()
				local acard = sgs.Card_Parse(card_str)
				assert(acard)
				use.card = acard
				if use.to then
					use.to:append(target)
				end
				return
			end
		end
	end
	return
end

sgs.ai_skill_playerchosen.xunxiao = function(self, targetlist)
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if targetlist:contains(enemy) then
			return enemy
		end
	end
	return targetlist:at(math.random(0, targetlist:length()-1))
end

sgs.ai_use_value["xunxiao"] = 2.2
sgs.ai_use_priority["xunxiao"] = 3.8

sgs.ai_cardneed.xunxiao = function(to, card)
	return card:isBlack() and to:getHandcardNum() <= 3
end





--嘲讽
sgs.ai_chaofeng.bailin_fujianshuimo = 1

--------------------------------------------------
--沉梦
--------------------------------------------------

local chenmeng_skill = {}
chenmeng_skill.name = "chenmeng"
table.insert(sgs.ai_skills, chenmeng_skill)
chenmeng_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#chenmeng") >= 1 or self.player:getHandcardNum() <= 2 or self:getDangerousCard(self.player) then return end
	return sgs.Card_Parse("#chenmeng:.:")
end
sgs.ai_skill_use_func["#chenmeng"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local cost_card
	for _, card in ipairs(cards) do
		if Ternary(self.player:getChangeSkillState("chenmeng") <= 1, card:isBlack(), card:isRed()) and (self:getUseValue(card) < 6 or self:getOverflow() >= 2) then
			cost_card = card
			break
		end
	end
	if not cost_card then return end
	
	local target
	local targets = sgs.SPlayerList()
	for _, enemy in ipairs(self.enemies) do
		if enemy:canDiscard(self.player, "he") and SkillCanTarget(enemy, self.player, "chenmeng") then
			targets:append(enemy)
		end
	end
	if targets:isEmpty() then return end
	
	local new_card = sgs.Sanguosha:cloneCard(Ternary(self.player:getChangeSkillState("chenmeng") <= 1, "supply_shortage", "indulgence"), sgs.Card_NoSuit, 0)
	new_card:addSubcard(cost_card:getEffectiveId())
	new_card:setSkillName("_chenmeng")
	
	local dummyuse = { isDummy = true, to = targets }
	self:useTrickCard(new_card, dummyuse)
	local targets = {}
	if not dummyuse.to:isEmpty() then
		target = dummyuse.to:first()
	end
	
	new_card:deleteLater()
	
	if target and cost_card then
		if use.to then
			use.to:append(target)
		end
		card_str = "#chenmeng:"..cost_card:getEffectiveId()..":->"..target:objectName()
		use.card = sgs.Card_Parse(card_str)
	end
end

sgs.ai_use_value["chenmeng"] = 1.8 --卡牌使用价值
sgs.ai_use_priority["chenmeng"] = sgs.ai_use_priority.Snatch - 0.1 --卡牌使用优先级（4.2）

sgs.ai_card_intention.chenmeng = function(self, card, from, tos)
    local to = tos[1]
    local intention = 10
    sgs.updateIntention(from, to, intention)
end

sgs.ai_skill_cardchosen.chenmeng = function(self, who, flags)
	if not self:isFriend(who) then
		local dangerous = self:getDangerousCard(who)
		if flags:match("e") and dangerous and self.player:canDiscard(who, dangerous) then return dangerous end
		if self:getOverflow() <= 0 and who:getHandcardNum() > 2 then
			local valuable = self:getValuableCard(who)
			if flags:match("e") and valuable and self.player:canDiscard(who, valuable) then return valuable end
		end
	end
	if not who:isKongcheng() then
		return who:getRandomHandCard()
	end
	return self:askForCardChosen(who, flags, "", sgs.Card_MethodDiscard)
end

--------------------------------------------------
--馋魔
--------------------------------------------------

sgs.ai_skill_invoke.chanmo = function(self, data)
	if data:toString() == "draw:" then
		return self:canDraw()
	elseif data:toString() == "use:" then
		self:updatePlayers()
		self:sort(self.enemies, "defense")
		
		local target_cards = {}
		for _, cd in sgs.qlist(self.player:getHandcards()) do
			if cd:hasFlag("chanmo") then
				table.insert(target_cards, cd)
			end
		end
		if #target_cards == 0 then
			return false
		end
		
		self:sortByUseValue(target_cards, true)
		target_cards = sgs.reverse(target_cards)
		
		for _,target_card in ipairs(target_cards) do
			if target_card:targetFixed() then
				if target_card:isKindOf("EquipCard") then
					local equip_index = target_card:getRealCard():toEquipCard():location()
					if (self.player:getEquip(equip_index) == nil or self.player:getHandcardNum() > self:getBestKeepHandcardNum()) and self.player:hasEquipArea(equip_index) then
						return true
					end
				end
				if target_card:isKindOf("Armor") then
					local equip_index = target_card:getRealCard():toEquipCard():location()
					if self.player:getEquip(equip_index) ~= nil and self.player:hasEquipArea(equip_index) and self:needToThrowArmor() then
						return true
					end
				end
				if target_card:isKindOf("SavageAssault") then
					local savage_assault = sgs.Sanguosha:cloneCard("SavageAssault")
					if self:getAoeValue(savage_assault) > 0 then
						savage_assault:deleteLater()
						return true
					end
					savage_assault:deleteLater()
				end
				if target_card:isKindOf("ArcheryAttack") then
					local archery_attack = sgs.Sanguosha:cloneCard("ArcheryAttack")
					if self:getAoeValue(archery_attack) > 0 then
						archery_attack:deleteLater()
						return true
					end
					archery_attack:deleteLater()
				end
				if target_card:isKindOf("Peach") and self.player:getLostHp() > 0 then
					return true
				end
				if target_card:isKindOf("ExNihilo") then
					return true
				end
			elseif target_card:isKindOf("TrickCard") then
				local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
				self:useTrickCard(target_card, dummyuse)
				if not dummyuse.to:isEmpty() then
					return true
				end
			elseif target_card:isKindOf("Slash") then
				local slash = target_card
				for _,enemy in ipairs(self.enemies) do	--yun
					if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) and self.player:canSlash(enemy, slash, true) then
						return true
					end
				end
			end
			if not self:canDraw(self.player) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_use["@@chanmo!"] = function(self, prompt, method)
	self:updatePlayers()
	
	local target_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:hasFlag("chanmo") then
			table.insert(target_cards, cd)
		end
	end
	if #target_cards == 0 then return end
	
	self:sortByUseValue(target_cards, true)
	target_cards = sgs.reverse(target_cards)
	
	for _,target_card in ipairs(target_cards) do
		if target_card:targetFixed() then
			return target_card:toString()
		else
			if target_card:isKindOf("Slash") then	--yun
				local to = self:findPlayerToSlash(true, target_card, nil, true)		--距离限制、卡牌、角色限制、必须选择
				return target_card:toString() .. "->" .. to:objectName()
			end
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(target_card, dummyuse)
			local targets = {}
			if not dummyuse.to:isEmpty() then
				for _, p in sgs.qlist(dummyuse.to) do
					table.insert(targets, p:objectName())
				end
				return target_card:toString() .. "->" .. table.concat(targets, "+")
			else		--强制选择随机目标
				local targets_list = sgs.PlayerList()
				for _, target in sgs.qlist(self.room:getAlivePlayers()) do
					targets_list:append(target)
				end
				local targets = {}
				for _,p in sgs.qlist(self.room:getAlivePlayers()) do
					if target_card:targetFilter(targets_list, p, self.player) and not sgs.Self:isProhibited(p, target_card) then
						table.insert(targets, p:objectName())
					end
				end
				if #targets > 0 then
					return target_card:toString() .. "->" .. targets[math.random(1,#targets)]
				end
			end
		end
	end
	return "."
end




--嘲讽
sgs.ai_chaofeng.bujumengli_keliyuesheng = 0

--------------------------------------------------
--贮歌
--------------------------------------------------

local zhuge_skill = {}
zhuge_skill.name = "zhuge"
table.insert(sgs.ai_skills, zhuge_skill)
zhuge_skill.getTurnUseCard = function(self)
	if self.player:getMark("zhuge_used") > 0 or not self:slashIsAvailable() then return end
	local card_str = "#zhuge:.:"
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash
end

sgs.ai_skill_use_func["#zhuge"] = function(card, use, self)
	self:sort(self.enemies, "defenseSlash")

	local dummy_use = { isDummy = true }
	dummy_use.to = sgs.SPlayerList()
	if self.player:hasFlag("slashTargetFix") then
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:hasFlag("SlashAssignee") then
				dummy_use.to:append(p)
			end
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	self:useCardSlash(slash, dummy_use)
	slash:deleteLater()
	if dummy_use.card and dummy_use.to:length() > 0 then
		local to_objnames = {}
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(to_objnames, p:objectName())
			if use.to then
				use.to:append(p)
			end
		end
		local card_str = "#zhuge:.:->"..table.concat(to_objnames, "+")
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		return
	end
end

sgs.ai_use_value["zhuge"] = 8.5
sgs.ai_use_priority["zhuge"] = sgs.ai_use_priority.Slash + 0.2

sgs.ai_card_intention.zhuge = function(self, card, from, tos)
	return sgs.ai_card_intention.Slash(self, card, from, tos)
end

sgs.ai_skill_invoke.zhuge = function(self, data)
	return true
end

function sgs.ai_cardsview_valuable.zhuge(self, class_name, player, need_lord)
	if class_name == "Slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and self.player:getMark("zhuge_used") == 0 then
		return "#zhuge:.:"
	end
end

--------------------------------------------------
--绝调
--------------------------------------------------

sgs.ai_skill_invoke.juediao = function(self, data)
	return true
end





--嘲讽
sgs.ai_chaofeng.shengge_wuxiugewu = 2

--------------------------------------------------
--雅和
--------------------------------------------------

sgs.ai_skill_choice.yahe = function(self, choices)
	if not self.player:getJudgingArea():isEmpty() then	--有判定牌就先观星
		return "yahe1"
	end
	
	local min_handcard_num = self.player:getHandcardNum()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:isAlive() and p:getHandcardNum() < min_handcard_num then
			min_handcard_num = p:getHandcardNum()
		end
	end
	local profit = 0
	for _, p in sgs.qlist(self.room:getAllPlayers()) do
		if p:isAlive() and p:getHandcardNum() == min_handcard_num then
			local ratio = 0
			if self:isFriend(p) then
				ratio = 1
			elseif self:isEnemy(p) then
				ratio = -1
			end
			if self:canDraw(p) then
				if p:hasSkills(sgs.cardneed_skill) then
					profit = profit + ratio*1.5
				else
					profit = profit + ratio*1
				end
			elseif p:isKongcheng() and self:needKongcheng(p) then
				profit = profit - ratio*2
			end
		end
	end
	if profit >= 0 then	--直接发牌收益为正就发牌
		return "yahe2"
	end
	
	local block_handcard = 0
	for _,cd in sgs.qlist(self.player:getHandcards()) do
		if not self:willUse(self.player, cd) then
			block_handcard = block_handcard + 1
		end
	end
	if not self:willSkipDrawPhase() then	--不跳过摸牌阶段就假设摸到的牌有1张是用不出去的
		block_handcard = block_handcard + 1
	end
	if self.player:hasSkills("maishu") then	--有埋薯就埋一张
		block_handcard = block_handcard - 1
	end
	if self.player:hasSkills("HLyingyuan") then	--有应援和存活队友就给一张
		for _, friend in ipairs(self.friends_noself) do
			if friend:isAlive() then
				block_handcard = block_handcard - 1
				break
			end
		end
	end
	block_handcard = math.min(self.player:getMaxCards(), block_handcard)
	if block_handcard < min_handcard_num or (block_handcard == min_handcard_num and profit > -1) then	--能把手牌用到最少或平级最少且收益为正，则观星
		return "yahe1"
	end
	
	return "cancel"
end

--------------------------------------------------
--埋薯
--------------------------------------------------

local maishu_skill={}
maishu_skill.name="maishu"
table.insert(sgs.ai_skills,maishu_skill)
maishu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#maishu") < 1 and (self.player:getHandcardNum() > self:getBestKeepHandcardNum() or self:needToThrowArmor()) then
		return sgs.Card_Parse("#maishu:.:")
	end
end
sgs.ai_skill_use_func["#maishu"] = function(card, use, self)
	if self:needToThrowArmor() and self.player:getArmor() and self.player:getArmor():isBlack() then
		card_str = "#maishu:"..self.player:getArmor():getEffectiveId()..":"
		use.card = sgs.Card_Parse(card_str)
		return
	end
	
	local cards = {}
	for _,card in sgs.qlist(self.player:getCards("h")) do
		if card:isBlack() then
			table.insert(cards, card)
		end
	end
	if #cards > 0 then
		local ids = dimeng_discard(self, 1, cards)
		if #ids > 0 then
			card_str = "#maishu:"..ids[1]..":"
			use.card = sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_priority["maishu"] = -1





--嘲讽
sgs.ai_chaofeng.xiaolingjiuhui_zuitianmimao = 2

--------------------------------------------------
--魔糕
--------------------------------------------------

sgs.ai_skill_cardask["@mogao_swap"] = function(self, data, pattern, target)
	local from = data:toPlayer()
	if not self:isEnemy(from) then		--给敌人最没使用价值的牌，未觉醒就直接给，否则不给价值超过6的牌
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(cards, false)
		for _, card in ipairs(cards) do
			if self:getUseValue(card) < 6 or (self.player:getLevelSkillState("mogao") < 2 and self.player:hasSkill("mishi") and self.player:getMark("mishi") == 0) then
				return "$" .. card:getEffectiveId()
			end
		end
		return "."
	else								--给非敌人最能用的价值<6的牌，如果是队友的话就无脑给
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(cards, true)
		for _, card in ipairs(cards) do
			if self:getUseValue(card) < 6 or self:isFriend(from) then
				return "$" .. card:getEffectiveId()
			end
		end
		return "."
	end
end




--嘲讽
sgs.ai_chaofeng.bingyuanbanling_youlinfuling = 3

--------------------------------------------------
--灵黯
--------------------------------------------------

sgs.ai_skill_playerchosen.lingan = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "handcard")
	
	local first, second, third
	
	for _, p in ipairs(targetlist) do
		if self:isEnemy(p) then
			if not first and p:hasSkills(sgs.recover_skill.."|xianwei|xunyi|shixi|qiyuanjuji|xinrong") then	--优先特化针对：主动回复系（救命系不算）和上限系（需要已损失体力值）
				first = p
			elseif not second and p:getLostHp() == 0 then	--其次是真的满血的敌人（被视为已受伤）
				second = p
			elseif not third then
				third = p
			end
		end
	end
	return first or second or third
end

sgs.ai_playerchosen_intention.lingan = function(self, from, to)
	local intention = 10
	sgs.updateIntention(from, to, intention)
end

sgs.ai_skill_cardask["@lingan_give"] = function(self, data, pattern, target)
	local from = data:toPlayer()
	--有也不给的情况：是敌人，且①体力上限有的是 ②不是满血、自己状态很残、没有回血手段，并且自己不依赖体力上限
	if ((self:isWeak() and getCardsNum("Peach", self.player, self.player, true) == 0 and self.player:getLostHp() > 0) or self.player:getMaxHp() > 4) and not self.player:hasSkills(sgs.recover_skill.."|xianwei|xunyi|shixi|qiyuanjuji|xinrong") and self.player:getMaxHp() > 2 and self:isEnemy(from) then
		return "."
	end
	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards, self:isFriend(from))
	for _, card in ipairs(cards) do
		if card:isBlack() and (self:getUseValue(card) < 6 or self:isFriend(from)) then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end




--嘲讽
sgs.ai_chaofeng.xiaoyesixingsha_fengjinmiyuan = 1

--------------------------------------------------
--秘恋
--------------------------------------------------

sgs.ai_skill_playerchosen.milian = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "chaofeng")	--实际上是按照防御值从高到低
	--targetlist = sgs.reverse(targetlist)
	
	for _, p in ipairs(targetlist) do
		return p
	end
	return nil
end

sgs.ai_skill_playerchosen.milianvs = sgs.ai_skill_playerchosen.milian

local milianvs_skill={}
milianvs_skill.name="milianvs"
table.insert(sgs.ai_skills,milianvs_skill)
milianvs_skill.getTurnUseCard=function(self,inclusive)
	local has_milian = self.player:hasSkill("milian")
	if not has_milian then
		for _, p in sgs.qlist(self.player:getSiblings()) do
			if p:isAlive() and p:hasSkill("milian") then
				has_milian = true
				break
			end
		end
	end
	if has_milian and self.player:usedTimes("#milianvs") < 1 then
		return sgs.Card_Parse("#milianvs:.:")
	end
end

sgs.ai_skill_use_func["#milianvs"] = function(card,use,self)
	if not use.isDummy then self:speak("milianvs") end
	use.card = card
end

sgs.ai_use_priority["milianvs"] = 8

sgs.ai_skill_askforag["milianvs"] = function(self, card_ids)
	local target = findPlayerByFlag(self.room, "milian_target_AI")
	
	local least_handcard
	if not self.player:isKongcheng() then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(cards, true)
		least_handcard = cards[1]
		if least_handcard and self:getUseValue(least_handcard) > 6 and self:isEnemy(target) then
			return -1
		end
	end
	self:sortIdsByValue(card_ids, "use", false)
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if self:willUse(self.player, card, false, false, true) and (self:getUseValue(card) >= 6 or (self:isFriend(target) and self:willSkipPlayPhase(target)) or (self.player:isKongcheng() and not card:isKindOf("AmazingGrace") and not card:isKindOf("Snatch"))) and (self.player:isKongcheng() or self:getUseValue(card) >= self:getUseValue(least_handcard) or self:isFriend(target)) then
			return id
		end
	end
	return -1
end

sgs.ai_skill_cardask["@milian_give"] = function(self, data, pattern, target)
	local from = data:toPlayer()
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, not self:isFriend(from))
	if self:isFriend(from) then
		for _, card in ipairs(cards) do
			if self:needCard(from, card) then		--新函数，返回某角色是否需要某张牌（根据cardneed）
				return "$" .. card:getEffectiveId()
			end
		end
	end
	for _, card in ipairs(cards) do
		return "$" .. card:getEffectiveId()
	end
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_skill_use["@@milianvs!"] = function(self, prompt, method)
	self:updatePlayers()
	
	local target_card = sgs.Sanguosha:getCard(self.player:getMark("milian_id")-1)
	if target_card then
		if target_card:targetFixed() then
			return target_card:toString()
		else
			if target_card:isKindOf("Slash") then	--yun
				local to = self:findPlayerToSlash(true, target_card, nil, true)		--距离限制、卡牌、角色限制、必须选择
				return target_card:toString() .. "->" .. to:objectName()
			end
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(target_card, dummyuse)
			local targets = {}
			if not dummyuse.to:isEmpty() then
				for _, p in sgs.qlist(dummyuse.to) do
					table.insert(targets, p:objectName())
				end
				return target_card:toString() .. "->" .. table.concat(targets, "+")
			else		--强制选择随机目标
				local targets_list = sgs.PlayerList()
				for _, target in sgs.qlist(self.room:getAlivePlayers()) do
					targets_list:append(target)
				end
				local targets = {}
				for _,p in sgs.qlist(self.room:getAlivePlayers()) do
					if target_card:targetFilter(targets_list, p, self.player) and not sgs.Self:isProhibited(p, target_card) then
						table.insert(targets, p:objectName())
					end
				end
				if #targets > 0 then
					return target_card:toString() .. "->" .. targets[math.random(1,#targets)]
				end
			end
		end
	end
	return "."
end




--嘲讽
sgs.ai_chaofeng.fenlier_xiaolangzai = 0

--------------------------------------------------
--邀击
--------------------------------------------------

sgs.ai_skill_playerchosen.yaoji = function(self, targetlist)
	local data = self.player:getTag("yaoji")
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "defense")
	for _, p in ipairs(targetlist) do
		if (self:isFriend(p) and not self:canDraw(p)) or (not self:isFriend(p) and self:canDraw(p)) then
			return p
		end
	end
	if data and data:toCardUse().card:isKindOf("IceSlash") then
		return nil
	end
	for _, p in ipairs(targetlist) do
		if self:willSkipPlayPhase(p) or (not self:hasCrossbowEffect(p) and not self:hasSlashAttackSkill(p) and not self:hasSlashCostSkill(p)) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.yaoji = function(self, from, to)
	local intention = 0
	if not self:canDraw(to) then
		intention = 10
	elseif self:willSkipPlayPhase(to) then
		intention = 0
	elseif self:isFriend(from, to) or (self:hasCrossbowEffect(to) or self:hasSlashAttackSkill(to) or self:hasSlashCostSkill(to)) then
		intention = -10
	end
	sgs.updateIntention(from, to, intention)
end

sgs.ai_cardneed.yaoji = function(to, card, self)
	if card:isKindOf("Slash") and self:getCardsNum("Slash") == 0 then
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.mengyinchanuo_xiuwaihuizhong = 2

--------------------------------------------------
--娴静
--------------------------------------------------

sgs.ai_skill_invoke.xianjing = function(self, data)
	local target = self.room:getCurrent()
	local last_judge = target:getJudgingArea():last()	--获取判定区最后一张牌（将第一个判定）
	if not last_judge then
		return false
	end
	if self:isFriend(target) then
		if not target:faceUp() or target:hasSkills("yangge") or target:getJudgingArea():length() > 1 then
			return true
		else
			if last_judge:isKindOf("Indulgence") and self:willSkipPlayPhase(target) then
				if self:getOverflow(target) > 0 or target:hasSkills("yishou|choucuo|xianwei|zhuoshi|shuoyi") then
					return true
				end
			end
			if last_judge:isKindOf("SupplyShortage") and self:willSkipDrawPhase(target) then
				if target:hasSkills("yishou|chouka|wanlong") then
					return true
				end
			end
		end
	elseif self:isEnemy(target) then
		if not target:faceUp() or target:hasSkills("yangge") or target:getJudgingArea():length() > 1 or last_judge:isKindOf("Lightning") then
			return false
		else
			if last_judge:isKindOf("Indulgence") and self:willSkipPlayPhase(target) then
				if self:getOverflow(target) < 0 and not target:hasSkills("yishou|choucuo|xianwei|zhuoshi|shuoyi") then
					return true
				end
			end
			if last_judge:isKindOf("SupplyShortage") and self:willSkipDrawPhase(target) then
				if target:getHandcardNum() <= 2 and not target:hasSkills("yishou|chouka|wanlong") then
					return true
				end
			end
		end
	end
	return false
end

--------------------------------------------------
--儒琴
--------------------------------------------------

sgs.ai_skill_playerchosen.ruqin = function(self, targetlist)
	local base_value = 10	--最低收益门槛，其中1牌价值为10
	return self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, targetlist, true, base_value, false)
end




--嘲讽
sgs.ai_chaofeng.ludisi_guguyisheng = 3

--------------------------------------------------
--止鸽
--------------------------------------------------

local zhige_gugu_skill={}
zhige_gugu_skill.name="zhige_gugu"
table.insert(sgs.ai_skills,zhige_gugu_skill)
zhige_gugu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#zhige_gugu") < 1 and not self.player:isKongcheng() and not self:needBear(self.player, false, nil) then
		return sgs.Card_Parse("#zhige_gugu:.:")
	end
end
sgs.ai_skill_use_func["#zhige_gugu"] = function(card, use, self)
	local cards = {}
	for _, card in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if card:isKindOf("Slash") and (not card:hasFlag("&gugu") or self:getOverflow() > 0) then
			table.insert(cards, card)
		end
	end
	if #cards == 0 then
		return
	end
	self:sortByUseValue(cards, false)
	
	local card, target_need = self:getCardNeedPlayer(cards, false)
	if target_need and target_need:isAlive() and card and self:canDraw(target_need) and not self:willSkipPlayPhase(target_need) then	--有需要某牌的队友，直接给
		if use.to then
			use.to:append(target_need)
		end
		card_str = "#zhige_gugu:"..card:getEffectiveId()..":->"..target_need:objectName()
		use.card = sgs.Card_Parse(card_str)
		return
	end
	
	local first, second
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend) and not self:willSkipPlayPhase(friend) and self.player:canEffect(friend, "zhige_gugu") then
			if not first then
				local no_gugu = true
				for _,cd in sgs.qlist(friend:getHandcards()) do
					if cd:hasFlag("&gugu") then
						no_gugu = false
						break
					end
				end
				if no_gugu then
					first = friend
				end
			end
			if not second then
				second = friend
			end
			if first and second then
				break
			end
		end
	end
	
	local target = first or second
	if target then
		local card_str = "#zhige_gugu:"..cards[1]:getEffectiveId()..":->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
		return
	end
end

sgs.ai_use_priority["zhige_gugu"] = 8

sgs.ai_card_intention.zhige_gugu = function(self, card, from, tos)
	if #tos > 0 then
		for _,to in ipairs(tos) do
			if self:canDraw(to) then
				sgs.updateIntention(from, to, -10)
			end
		end
	end
	return 0
end

sgs.ai_cardneed.zhige_gugu = function(to, card, self)
	if card:isKindOf("Slash") and self:getCardsNum("Slash") == 0 then
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.shuishutumian_xishizhenbao = 1

--------------------------------------------------
--奉声
--------------------------------------------------

sgs.ai_skill_invoke.fengsheng = function(self, data)
	return self.player:getMark("@shenyuan") < 13 and not self.player:isKongcheng()
end

sgs.ai_skill_askforag["fengsheng"] = function(self, card_ids)
	self:sortIdsByValue(card_ids, "use", false)
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if self:willUse(self.player, card, false, false, true) then
			return id
		end
	end
	return card_ids[1]
end

local fengsheng_skill = {}
fengsheng_skill.name = "fengsheng"
table.insert(sgs.ai_skills, fengsheng_skill)
fengsheng_skill.getTurnUseCard = function(self, inclusive)
	local obj_name
	for _, mark in sgs.list(self.player:getMarkNames()) do
		if string.startsWith(mark, "&fengsheng+") and self.player:getMark(mark) > 0 then
			obj_name = string.sub(mark, 12, -1)
			break
		end
	end
	if self.player:getMark("fengsheng_used") == 0 and self.player:getPhase() == sgs.Player_Play and obj_name then
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		local trans_card
		self:sortByKeepValue(cards)
	
		local virtual_card = sgs.Sanguosha:cloneCard(obj_name)
		local class_name = virtual_card:getClassName()
		for _, card in ipairs(cards) do
			if not card:hasFlag("using") and (self:getKeepValue(card) <= 5 and self:getUseValue(card) < sgs.ai_use_value[class_name]) or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, virtual_card) > 0 then
				trans_card = card
				break
			end
		end
		virtual_card:deleteLater()

		if trans_card then
			local suit = trans_card:getSuitString()
			local number = trans_card:getNumberString()
			local card_id = trans_card:getEffectiveId()
			local card_str = ("%s:fengsheng[%s:%s]=%d"):format(obj_name, suit, number, card_id)
			local new_card = sgs.Card_Parse(card_str)
	
			assert(new_card)
			return new_card
		end
	end
end

sgs.ai_view_as.fengsheng = function(card, player, card_place)
	local obj_name
	for _, mark in sgs.list(player:getMarkNames()) do
		if string.startsWith(mark, "&fengsheng+") and player:getMark(mark) > 0 then
			obj_name = string.sub(mark, 12, -1)
			break
		end
	end
	if player:getMark("fengsheng_used") == 0 and player:getPhase() == sgs.Player_Play and obj_name then
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		if card_place == sgs.Player_PlaceHand and not card:hasFlag("using") then
			return ("%s:fengsheng[%s:%s]=%d"):format(obj_name, suit, number, card_id)
		end
	end
end

--------------------------------------------------
--奉声（新）
--------------------------------------------------

sgs.ai_skill_invoke.newfengsheng = function(self, data)
	return true
end

--奉声主要拿以下卡
local newfengsheng_good_card = {"peach", "analeptic", "nullification", "ex_nihilo", "snatch", "archery_attack", "savage_assault", "duel"}

sgs.ai_skill_cardask["@newfengsheng"] = function(self, data, pattern, target)
	local card
	if self.player:hasFlag("newfengsheng_use") then
		card = data:toCardUse().card
	elseif self.player:hasFlag("newfengsheng_response") then
		card = response.m_card
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _, cd in ipairs(cards) do
		if (card:isKindOf("BasicCard") and not cd:isKindOf("BasicCard")) or (card:isNDTrick() and not cd:isKindOf("TrickCard")) then
			local use_value = self:getUseValue(card)
			--for _, card_id in sgs.qlist(card:getSubcards()) do
			--	use_value = use_value + self:getUseValue(sgs.Sanguosha:getCard(card_id))
			--end
			--self.player:speak(use_value)
			if (self:getUseValue(cd) < use_value) and table.contains(newfengsheng_good_card, card:objectName()) and not (self:isWeak() and (cd:isKindOf("Peach") or cd:isKindOf("Jink") or cd:isKindOf("Analeptic"))) and not (cd:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
				return "$" .. cd:getEffectiveId()
			end
		end
	end
	return "."
end

sgs.ai_cardneed.newfengsheng = function(to, card, self)
	return card:isKindOf("EquipCard") or self.player:isKongcheng()
end




--嘲讽
sgs.ai_chaofeng.bubuzi_daidaihuashen = 1

--------------------------------------------------
--给我心心（交牌部分）
--------------------------------------------------

sgs.ai_skill_discard.geiwoxinxin = function(self, discard_num, min_num, optional, include_equip)
	local toDis = {}
	local target = findPlayerByFlag(self.room, "geiwoxinxin_receiver_AI")
	if target and self:isFriend(target) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(cards, false)
		for _, card in ipairs(cards) do
			if self:needCard(target, card) then		--新函数，返回某角色是否需要某张牌（根据cardneed）
				table.insert(toDis, card:getEffectiveId())
				return toDis
			end
		end
		table.insert(toDis, cards[1]:getEffectiveId())
		return toDis
	end
	return self:askForDiscard("", discard_num, min_num, optional, include_equip)
end

--------------------------------------------------
--跳水表演
--------------------------------------------------

sgs.ai_skill_use["@@tiaoshuibiaoyan"] = function(self, prompt)
    local targets = {}
	for _, to in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if (not self:isFriend(to) or self:needKongcheng(to)) and not to:isNude() and SkillCanTarget(to, self.player, "tiaoshuibiaoyan") and self.player:canEffect(p, "tiaoshuibiaoyan") then
            table.insert(targets, to:objectName())
        end 
    end
	if #targets > 0 then
		return "#tiaoshuibiaoyan:.:->"..table.concat(targets, "+")
	end
end




--嘲讽
sgs.ai_chaofeng.muyun_lanwenbianjian = 2

--------------------------------------------------
--情容
--------------------------------------------------

sgs.ai_skill_playerchosen.qingrong = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "handcard")
	targetlist = sgs.reverse(targetlist)
	
	local first, second, third
	
	for _, p in ipairs(targetlist) do
		if not self:isFriend(p) then
			if self:isEnemy(p) then		--排除最优先攻击的目标
				for _, to in sgs.qlist(self:getFirstAttackTarget()) do
					if p:objectName() == to:objectName() then
						goto qingrong_label
					end
				end
			end
			if not first and self.player:hasSkill("pinsheng") and p:getHandcardNum() >= 3 then	--若有“品生”，优先对3+手牌角色使用
				first = p
			elseif not second and p:hasSkills(sgs.notActive_cardneed_skill) then	--其次对回合外需要手牌的角色使用
				second = p
			elseif not third then	--最后对手牌最多（已排序）的角色使用
				third = p
			end
		end
		::qingrong_label::
	end
	--[[if self:getOverflow() > 2 then	--克己打法，但好像没什么意义
		second = self.player
	end]]
	return first or second or third
end

sgs.ai_playerchosen_intention.qingrong = function(self, from, to)
	local intention = 10
	sgs.updateIntention(from, to, intention)
end

--------------------------------------------------
--品生
--------------------------------------------------

sgs.ai_skill_invoke.pinsheng = function(self, data)
	local objname = data:toString():split(":")[2]	--截取第二部分，也就是%src(即player:objectName())
	local to = findPlayerByObjName(self.room, objname)
	if to then
		if not self:isFriend(to) then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardask["#pinsheng_put"] = function(self, data, pattern, target)
	local ids = dimeng_discard(self, 1, sgs.QList2Table(self.player:getCards("h")))
	return "$" .. ids[1]
end

sgs.ai_choicemade_filter.skillInvoke.pinsheng = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = findPlayerByObjName(self.room, "pinsheng_AI")
		if target then sgs.updateIntention(player, target, 10) end
	end
end




--嘲讽
sgs.ai_chaofeng.tongguhesha_cpmode = -1

--------------------------------------------------
--法魂
--------------------------------------------------

local function card_for_qiaobian(self, who, return_prompt)	--魔改自巧变，但可以同时返回移动的牌和移动目标两个值
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (enemy:hasSkill("hongyan") or judge:isKindOf("Lightning")) then
							target = enemy
							break
						end
					end
					if target then break end
				end
			end
		end

		local equips = who:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip break
				elseif equip:isKindOf("Weapon") then card = equip break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
							target = friend
							break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	else
		local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					card = sgs.Sanguosha:getCard(judge:getEffectiveId())
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge)
							and not friend:getJudgingArea():isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge) then
							target = friend
							break
						end
					end
					if target then break end
				end
			end
		end
		if card==nil or target==nil then
			if not who:hasEquip() or self:hasSkills(sgs.lose_equip_skill, who) then return nil end
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and self:hasSkills(sgs.lose_equip_skill .. "|shensu" , friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	end

	if return_prompt == "card" then return card
	elseif return_prompt == "target" then return target
	else
		local return_table = {}
		if card and target then
			table.insert(return_table, card)
			table.insert(return_table, target)
		end
		return return_table
	end
end

sgs.ai_skill_use["@@fahun"] = function(self, prompt)
	if self.player:isKongcheng() then return "" end
	if not self.fahun_card_id then
		self.fahun_card_id = -1	--先确定此变量为int类型
	end
	
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)

	self:sort(self.enemies, "defense")
	self:sort(self.friends, "defense")
	self:sort(self.friends_noself, "defense")

	for _, friend in ipairs(self.friends) do
		if not friend:getCards("j"):isEmpty() and not friend:containsTrick("YanxiaoCard") then
			local move_table = card_for_qiaobian(self, friend, ".")
			if move_table and move_table ~= {} then
				self.fahun_card_id = move_table[1]:getEffectiveId()
				return "#fahun:"..cards[1]:getEffectiveId()..":->"..friend:objectName().."+"..move_table[2]:objectName()
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard")then
			local move_table = card_for_qiaobian(self, enemy, ".")
			if move_table and move_table ~= {} then
				self.fahun_card_id = move_table[1]:getEffectiveId()
				return "#fahun:"..cards[1]:getEffectiveId()..":->"..enemy:objectName().."+"..move_table[2]:objectName()
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if not friend:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill, friend) then
			local move_table = card_for_qiaobian(self, friend, ".")
			if move_table and move_table ~= {} then
				self.fahun_card_id = move_table[1]:getEffectiveId()
				return "#fahun:"..cards[1]:getEffectiveId()..":->"..friend:objectName().."+"..move_table[2]:objectName()
			end
		end
	end

	local top_value = 0
	for _, hcard in ipairs(cards) do
		if not hcard:isKindOf("Jink") then
			if self:getUseValue(hcard) > top_value then top_value = self:getUseValue(hcard) end
		end
	end
	if top_value >= 3.7 and #(self:getTurnUse())>0 then return "" end

	for _, enemy in ipairs(self.enemies) do
		if not enemy:getCards("ej"):isEmpty() and not self:hasSkills(sgs.lose_equip_skill, enemy) then
			local move_table = card_for_qiaobian(self, enemy, ".")
			if move_table and move_table ~= {} then
				self.fahun_card_id = move_table[1]:getEffectiveId()
				return "#fahun:"..cards[1]:getEffectiveId()..":->"..enemy:objectName().."+"..move_table[2]:objectName()
			end
		end
	end
end

sgs.ai_skill_askforag["fahun"] = function(self, card_ids)
	return self.fahun_card_id or -1
end





--嘲讽
sgs.ai_chaofeng.sabimeng_bimengjushou = 0

--------------------------------------------------
--视幻
--------------------------------------------------

sgs.ai_skill_invoke.shihuan = function(self, data)
	local target = self.room:getCurrent()
	local N = math.max(1, target:getHandcardNum())
	local max_cards = target:getMaxCards()
	local will_draw_to = target:getHandcardNum() + (self:willSkipDrawPhase(target) and 0 or self:ImitateResult_DrawNCards(target, target:getVisibleSkillList(true)))
	
	if self:isFriend(target) then
		if N > max_cards and will_draw_to > max_cards then
			return true
		end
	elseif self:isEnemy(target) then
		if N == 1 and will_draw_to >= 1 then
			return true
		elseif N < max_cards and will_draw_to > N then
			return true
		end
	end
	return false
end





--嘲讽
sgs.ai_chaofeng.anwan_yingganlingxin = 0

--------------------------------------------------
--占术
--------------------------------------------------

sgs.ai_skill_invoke.zhanshu = function(self, data)
	return true
end

sgs.ai_skill_askforag["zhanshu_select"] = function(self, card_ids)
	local black_profit = 0
	local red_profit = 0
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isRed() then
			red_profit = red_profit + 1
			if card:isKindOf("TrickCard") then
				red_profit = red_profit + 0.8
			end
		end
		if card:isBlack() then
			black_profit = black_profit + 1
			if card:isKindOf("TrickCard") then
				black_profit = black_profit + 0.8
			end
		end
	end
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isRed() and red_profit >= black_profit then
			return id
		elseif card:isBlack() and red_profit < black_profit then
			return id
		end
	end
	return card_ids[1]
end

sgs.ai_skill_askforag["zhanshu_get"] = function(self, card_ids)
	self:sortIdsByValue(card_ids, "use", false)
	return card_ids[1]
end

sgs.ai_cardneed.zhanshu = function(to, card, self)
	return card:isKindOf("TrickCard")
end

--------------------------------------------------
--通感
--------------------------------------------------

sgs.ai_skill_use["@@tonggan"] = function(self, prompt, method)
    local judge = self.player:getTag("judgeData"):toJudge()
    local ids = self.player:getPile("zhanshu_pile")
    if self.room:getMode():find("_mini_46") and not judge:isGood() then return "#tonggan:" .. ids:first() .. ":" end
    local cards = {}
    for _,id in sgs.qlist(ids) do
        table.insert(cards,sgs.Sanguosha:getCard(id))
    end
    if self:needRetrial(judge) then
        local card_id = self:getRetrialCardId(cards, judge)
        if card_id ~= -1 then
            return "#tonggan:" .. card_id .. ":"
        end
	elseif self.player:getLostHp() > 0 then
		self:sortByUseValue(cards, true)
		for _, card in ipairs(cards) do
			local card_x = sgs.Sanguosha:getEngineCard(card:getEffectiveId())
			if (judge:isGood() and judge:isGood(card_x)) or (not judge:isGood() and not judge:isGood(card_x)) then
				return "#tonggan:" .. card:getEffectiveId() .. ":"
			end
		end
    end
    return "."
end





--嘲讽
sgs.ai_chaofeng.yuenaiying_yuebenlangshen = 0

--------------------------------------------------
--盈异
--------------------------------------------------

sgs.ai_skill_choice.yingyi = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	elseif #items == 2 and table.contains(items, "cancel") then
		if table.contains(items, "slash") then
			return "slash"
		elseif table.contains(items, "duel") then
			return "duel"
		end
	else
		local slash_use_value = -10
		local duel_use_value = -10
		
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		cards = sgs.reverse(cards)
		
		for _,card in ipairs(cards) do
			if card:isBlack() then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:addSubcard(card)
				slash:setSkillName("yingyi")
				if self:willUse(self.player, slash) and self:getUseValue(slash) > slash_use_value then
					slash_use_value = self:getUseValue(slash)
				end
				slash:deleteLater()
				
				local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
				duel:addSubcard(card)
				duel:setSkillName("yingyi")
				if self:willUse(self.player, duel) and self:getUseValue(duel) > duel_use_value then
					duel_use_value = self:getUseValue(duel)
				end
				duel:deleteLater()
			end
		end
		
		if duel_use_value > slash_use_value and duel_use_value > -10 then
			return "duel"
		elseif duel_use_value <= slash_use_value and slash_use_value > -10 then
			return "slash"
		end
	end
	return "cancel"
end

sgs.ai_skill_use["@@yingyi"] = function(self, prompt, method)
	self:updatePlayers()
	
	local target_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:isBlack() then
			table.insert(target_cards, cd)
		end
	end
	if #target_cards == 0 then return end
	
	self:sortByUseValue(target_cards, true)
	target_cards = sgs.reverse(target_cards)
	
	local obj_name
	if self.player:getMark("&yingyi+slash") > 0 then
		obj_name = "slash"
	elseif self.player:getMark("&yingyi+duel") > 0 then
		obj_name = "duel"
	end
	if obj_name and obj_name ~= "" then
		for _,target_card in ipairs(target_cards) do
			local new_card = sgs.Sanguosha:cloneCard(obj_name, target_card:getSuit(), target_card:getNumber())
			new_card:addSubcard(target_card)
			new_card:setSkillName("yingyi")
			
			--if self:getUseValue(target_card) > self:getUseValue(new_card) then continue end
			
			local dummyuse = { isDummy = true, to = sgs.SPlayerList()}
			if obj_name == "slash" then
				self:useBasicCard(new_card, dummyuse)
			elseif obj_name == "duel" then
				self:useTrickCard(new_card, dummyuse)
			end
			if dummyuse.card and not dummyuse.to:isEmpty() then
				local to_objnames = {}
				for _, p in sgs.qlist(dummyuse.to) do
					table.insert(to_objnames, p:objectName())
				end
				local result = new_card:toString() .. "->" .. table.concat(to_objnames, "+")
				new_card:deleteLater()
				return result
			end
			new_card:deleteLater()
		end
	end
	return "."
end

function sgs.ai_cardneed.yingyi(to, card, self)
	return card:isKindOf("Black") and self:getOverflow(to) <= 0
end



--嘲讽
sgs.ai_chaofeng.limo_longshengjiangjiao = 1

--------------------------------------------------
--玄鳞
--------------------------------------------------

sgs.ai_skill_discard.xuanlin = function(self, discard_num, min_num, optional, include_equip)
	local toDis = {}
	local will_use = false
	
	if self.player:getEquips():length() < 5 then
		will_use = true
	end
	
	if will_use then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isBlack() and #toDis < 2 then		--新函数，返回某角色是否需要某张牌（根据cardneed）
				table.insert(toDis, card:getEffectiveId())
				if #toDis == 2 then
					break
				end
			end
		end
	end
	
	if #toDis < 2 then
		return {}
	end
	return toDis
end

sgs.ai_skill_choice.xuanlin = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if table.contains(items, "jueyan1") and (self.player:getEquip(1) == nil or self:needToThrowArmor()) then
			return "jueyan1"
		end
		if table.contains(items, "jueyan0") and self.player:getEquip(0) == nil then
			return "jueyan0"
		end
		if table.contains(items, "jueyan2") and self.player:getEquip(2) == nil then
			return "jueyan2"
		end
		if table.contains(items, "jueyan4") and self.player:getEquip(4) == nil then
			return "jueyan4"
		end
		if table.contains(items, "jueyan3") and self.player:getEquip(3) == nil then
			return "jueyan3"
		end
	end
	return items[1] or ""
end




--嘲讽
sgs.ai_chaofeng.xianyu_xiangluancuxian = 2

--------------------------------------------------
--抹挑
--------------------------------------------------

sgs.ai_skill_invoke.motiao = function(self, data)
	local damage_count = 0
	local slash_damage_count = 0
	local has_crossbow = false
	local draw_count = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Crossbow") then
			has_crossbow = true
		end
		if (card:isKindOf("Peach") or card:isKindOf("Analeptic") or card:isKindOf("EquipCard") or card:isKindOf("ExNihilo") or card:isKindOf("AmazingGrace") or card:isKindOf("GodSalvation") or card:isKindOf("Fudichouxin")) and self:willUse(self.player, card) then
			draw_count = draw_count + 1
		elseif card:isDamageCard() and not card:isKindOf("Lightning") and self:willUse(self.player, card) then
			if card:isKindOf("Slash") then
				slash_damage_count = slash_damage_count + 1
			else
				damage_count = damage_count + 1
			end
		end
	end
	if slash_damage_count > 0 and self:hasCrossbowEffect(self.player) or has_crossbow then
		damage_count = damage_count + slash_damage_count
	elseif slash_damage_count > 0 then
		damage_count = damage_count + 1
	end
	if damage_count >= 3 and draw_count <= 4 then
		return false
	end
	return true
end

sgs.ai_cardneed.motiao = function(to, card, self)
	return (card:isKindOf("Peach") and to:getLostHp() > 0) or card:isKindOf("Analeptic") or card:isKindOf("EquipCard") or card:isKindOf("ExNihilo") or card:isKindOf("AmazingGrace") or card:isKindOf("GodSalvation") or (card:isKindOf("Fudichouxin") and not to:getEquips():isEmpty()) or card:isKindOf("FireAttack")
end

--------------------------------------------------
--连奏
--------------------------------------------------

sgs.ai_skill_invoke.lianzou = function(self, data)
	return true
end



--嘲讽
sgs.ai_chaofeng.shanjiaoalubo_liuciyuanouxiang = 1

--------------------------------------------------
--扬音
--------------------------------------------------

sgs.ai_skill_invoke.yangyin = function(self, data)
	return true
end

--------------------------------------------------
--惊弦
--------------------------------------------------

sgs.ai_skill_playerchosen.jingxian = function(self, targetlist)
	local target = self:findPlayerToDiscard("e", false, true, targetlist)
	if not target and targetlist:contains(self.player) then
		target = self.player
	end
	if target then
		targetlist = sgs.QList2Table(targetlist)
		for _, p in ipairs(targetlist) do
			if p:objectName() == target:objectName() then
				return p
			end
		end
	end
	return nil
end

sgs.ai_skill_cardchosen.jingxian = function(self, who, flags)
	if self.player:objectName() == who:objectName() then
		return self:askForDiscard("", 1, 1, false, true)[1]
	end
	return self:askForCardChosen(who, flags, "", sgs.Card_MethodDiscard)
end

sgs.ai_skill_cardask["@jingxian_dismantle"] = function(self, data, pattern, target)
	return "$" .. self:askForDiscard("", 1, 1, false, true)[1]
end





--嘲讽
sgs.ai_chaofeng.daoheyue_daohezhihu = 0

--------------------------------------------------
--丰收
--------------------------------------------------

sgs.ai_skill_invoke.fengshou = function(self, data)
	local amazing_grace = sgs.Sanguosha:cloneCard("amazing_grace", sgs.Card_NoSuit, 0)
	amazing_grace:setSkillName("fengshou")
	if self:willUse(self.player, amazing_grace) then
		amazing_grace:deleteLater()
		return true
	end
	amazing_grace:deleteLater()
	return false
end

--------------------------------------------------
--布恩
--------------------------------------------------

sgs.ai_skill_playerchosen["buen"] = function(self, targets)
	local data = self.room:getTag("buenData")
	local use = data:toCardUse()
	local friend_targets = {}
	local enemies_targets = {}
	for _, p in ipairs(sgs.QList2Table(targets)) do
		if self:isFriend(p) then
			table.insert(friend_targets, p)
		elseif self:isEnemy(p) then
			table.insert(enemies_targets, p)
		end
	end
	self:sort(friend_targets, "hp")
	self:sort(enemies_targets, "hp")
	if use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") then
		for _, p in ipairs(sgs.QList2Table(targets)) do
			if p:hasSkill("guixin") and (p:getHp() > 1 or p:getHandcardNum() > 7) and self:isEnemy(p) then
				return p
			end
		end
		for _, friend in ipairs(friend_targets) do
			if use.to:contains(friend) then
				return friend
			end
		end
	end
	if use.card:isKindOf("ExNihilo") then
		for _, friend in ipairs(friend_targets) do
			return friend
		end
	end
	if use.card:isKindOf("AmazingGrace") or use.card:isKindOf("GodSalvation") or use.card:isKindOf("Duel") then
		for _, enemy in ipairs(enemies_targets) do
			return enemy
		end
	end
	--[[if use.card:isKindOf("FireAttack") then
		for _, enemy in ipairs(enemies_targets) do
			if enemy:getHandcardNum() > 0 then
				return enemy
			end
		end
	end]]
	if (use.card:isKindOf("Snatch") and not self:isEnemy(use.from)) or use.card:isKindOf("Dismantlement") then
		for _, enemy in ipairs(enemies_targets) do
			if enemy:getHandcardNum() > 0 and enemy:getCards("j"):isEmpty() then
				return enemy
			end
		end
	end
	--[[if use.card:isKindOf("IronChain") then
		if self.player:isChained() then
			for _, enemy in ipairs(enemies_targets) do
				return enemy
			end
		else
			return self.player
		end
	end]]
	return nil
end

sgs.ai_playerchosen_intention["buen"] = function(self, from, to)
	local data = self.room:getTag("buenData")
	local use = data:toCardUse()
	if use.card and from:objectName() ~= to:objectName() then
		if use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") then
			if to:hasSkill("guixin") and (to:getHp() > 1 or to:getHandcardNum() > 7) then
				sgs.updateIntention(from, to, 10)
			end
			sgs.updateIntention(from, to, -10)
		end
		if use.card:isKindOf("ExNihilo") then
			sgs.updateIntention(from, to, -10)
		end
		if use.card:isKindOf("AmazingGrace") or use.card:isKindOf("GodSalvation") or use.card:isKindOf("Duel") then
			sgs.updateIntention(from, to, 10)
		end
		if use.card:isKindOf("FireAttack") then
			sgs.updateIntention(from, to, 10)
		end
		if use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") then
			sgs.updateIntention(from, to, 10)
		end
		if use.card:isKindOf("IronChain") then
			sgs.updateIntention(from, to, 10)
		end
	end
end

sgs.ai_cardneed.buen = function(to, card, self)
	return card:isKindOf("ExNihilo")
end



--嘲讽
sgs.ai_chaofeng.taoshuiji_fenhuafutao = -1

--------------------------------------------------
--芳仙
--------------------------------------------------

sgs.ai_skill_invoke.fangxian = function(self, data)
	if self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) > 2 then
		return false
	end
	return true
end

sgs.ai_skill_playerchosen.fangxian = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "hp")
	
	for _, p in ipairs(targetlist) do
		if self:isFriend(p) and self:isWeak(p, p:objectName() == self.player:objectName()) and p:getLostHp() > 0 and not self:needToLoseHp(p, self.player, false, false, true) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.fangxian = function(self, from, to)
	local intention = -10
	sgs.updateIntention(from, to, intention)
end



--嘲讽
sgs.ai_chaofeng.cangyuling_qionglingjinque = 1

--------------------------------------------------
--灵羽
--------------------------------------------------

local lingyu_skill={}
lingyu_skill.name="lingyu"
table.insert(sgs.ai_skills,lingyu_skill)
lingyu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#lingyu") < 1 and not self.player:isKongcheng() then
		return sgs.Card_Parse("#lingyu:.:")
	end
end
sgs.ai_skill_use_func["#lingyu"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	for _, vic in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if SkillCanTarget(vic, self.player, "lingyu") and self.player:canEffect(vic, "lingyu") then
			targets:append(vic)
		end
	end
	if targets:isEmpty() then return end
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local first = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Thunder, targets, false, 0, false)	--优先找适合造成伤害的目标（默认期望为雷伤）
	if not first then
		local second, third
		for _, target in ipairs(targets) do
			if not second and self:isEnemy(target) and not self:needToLoseHp(target) and not target:hasSkills(sgs.masochism_skill) then	--needToLoseHp的第五个参数为真则考虑回血后情况
				second = target
			end
			if not third then
				third = target
			end
			if second and third then
				break
			end
		end
	end
	
	local to = first or second or third or nil
	if to then
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		local ids = dimeng_discard(self, 1, cards)
		if use.to then
			use.to:append(to)
		end
		card_str = "#lingyu:"..ids[1]..":->"..to:objectName()
		use.card = sgs.Card_Parse(card_str)
	end
end

sgs.ai_use_priority["lingyu"] = 8

sgs.ai_card_intention.lingyu = function(self, card, from, tos)
	if #tos > 0 then
		for _,to in ipairs(tos) do
			if not self:needToLoseHp(to) and not to:hasSkills(sgs.masochism_skill) and not self:isFriend(to, from) then
				sgs.updateIntention(from, to, 10)
			end
		end
	end
	return 0
end

--------------------------------------------------
--澄涤
--------------------------------------------------

sgs.ai_skill_discard.chengdi = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("", discard_num, min_num, optional, include_equip)
end



--嘲讽
sgs.ai_chaofeng.zihaiyouai_xiguamiao = -1

--------------------------------------------------
--音爆
--------------------------------------------------

function canBeLockBird(player)	--判断某角色是否适合被锁鸟
	if player:getPhase() <= sgs.Player_Play then
		if player:hasSkills("zhuoshi|xianwei|yongxing|xixue|muguang|jingxian|xiangchu|shuoyi|pianpian|lianjie|jixue|motiao") then
			return true
		end
	elseif player:getPhase() == sgs.Player_NotActive then
		if player:hasSkills("qingrou|mogao") then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardask["@yinbao_invoke"] = function(self, data, pattern, target)
	local move = data:toMoveOneTime()
	if not move or not move.to then
		return "."
	end
	local to = findPlayerByObjName(self.room, move.to:objectName())
	if not to then return "." end
	
	if self:isEnemy(to) and canBeLockBird(to) then
		return "$" .. self:askForDiscard("", 1, 1, false, false)[1]
	end
	
	if not self:isFriend(to) then		--或者只通过这个技能解决自己的卡手问题
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if self:getKeepValue(card, true, true) < 0 then		--getKeepValue第三个参数为true代表计算技能对keepvalue的影响
				return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end



--嘲讽
sgs.ai_chaofeng.nimo_avatarofevil = 1

--------------------------------------------------
--险至
--------------------------------------------------

sgs.ai_skill_invoke.xianzhi = function(self, data)
	return true
end

--------------------------------------------------
--冥邀
--------------------------------------------------

sgs.ai_skill_playerchosen.mingyao = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "hp")
	
	for _, p in ipairs(targetlist) do
		if self:isEnemy(p) and (self:isWeak(p, p:objectName() == self.player:objectName()) or self:isWeak(self.player, true)) then	--对脆弱敌人用，或者自己要死了也赶紧用
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.mingyao = function(self, from, to)
	local intention = 10
	sgs.updateIntention(from, to, intention)
end



--嘲讽
sgs.ai_chaofeng.zhanyue_pomiezhiqiang = 2

--------------------------------------------------
--默月
--------------------------------------------------

sgs.ai_skill_invoke.moyue = function(self, data)
	return self:canDraw() and self.player:getHandcardNum() <= 4
end

--------------------------------------------------
--贯袭
--------------------------------------------------

sgs.ai_skill_cardask["@guanxi_use"] = function(self, data, pattern, target)
	local to = self.room:getCurrent()
	local targets = sgs.SPlayerList()
	targets:append(to)
	
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:hasFlag("guanxi_flag") then
			if card:isKindOf("Slash") and self:findPlayerToSlash(true, card, targets, false) then	--yun
				return "$" .. card:getEffectiveId()
			elseif card:isKindOf("TrickCard") then
				if card:isKindOf("IronChain") and not (player:getWeapon() and player:getWeapon():isKindOf("SPMoonSpear") and card:isBlack()) then	--铁索如果不是能触发银月枪的话，就别用了
					return "."
				end
				
				local dummyuse = { isDummy = true, to = sgs.SPlayerList(), extra_target = 999 }		--允许加无限多个目标，以选出所有适合用的目标
				self:useTrickCard(card, dummyuse)
				local targets = {}
				if not dummyuse.to:isEmpty() and dummyuse.to:contains(to) then	--若当前目标角色在所有合适目标中，则使用
					return "$" .. card:getEffectiveId()
				end
			end
		end
	end
	return "."
end

sgs.ai_cardneed.guanxi = function(to, card, self)
	return to:getPhase() == sgs.Player_NotActive and (card:isKindOf("Slash") or card:isKindOf("Duel"))
end




--嘲讽
sgs.ai_chaofeng.xiabubu_zhixingjiejie = 0

--------------------------------------------------
--紫禁
--------------------------------------------------

sgs.ai_skill_playerchosen.zijin = function(self, targetlist)
	local nonbasic_count = 0
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if not card:isKindOf("BasicCard") then
			nonbasic_count = nonbasic_count + 1
		end
	end
	if nonbasic_count > 0 or (self.player:hasSkill("benbu") and self.player:getMark("benbu") == 0) then		--未觉醒或有非基本
		local base_value = 10	--最低收益门槛，其中1牌价值为10
		return self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, targetlist, true, base_value, false)
	end
	return nil
end

sgs.ai_playerchosen_intention.zijin = function(self, from, to)
	local intention = 10
	sgs.updateIntention(from, to, intention)
end

sgs.ai_skill_cardchosen.zijin = function(self, who, flags)
	if not self:needToLoseHp(self.player) and not self:isWeak(self.player, true) then
		local dangerous = self:getDangerousCard(who)
		if flags:match("e") and dangerous and self.player:canDiscard(who, dangerous) then return dangerous end
		if who:getHandcardNum() > 2 then
			local valuable = self:getValuableCard(who)
			if flags:match("e") and valuable and self.player:canDiscard(who, valuable) then return valuable end
		end
	end
	if not who:isKongcheng() then
		return who:getRandomHandCard()
	end
	return self:askForCardChosen(who, flags, "", sgs.Card_MethodDiscard)
end

--------------------------------------------------
--触手
--------------------------------------------------

sgs.ai_need_damaged.chushou = sgs.ai_need_damaged.xuelin	--直接借用血林





--嘲讽
sgs.ai_chaofeng.zhangege_v2 = 0

--------------------------------------------------
--梦见
--------------------------------------------------

sgs.ai_skill_invoke.mengjian = function(self, data)
	return true
end

--------------------------------------------------
--漂泊
--------------------------------------------------

sgs.ai_skill_invoke.piaobo = function(self, data)
	local objname = string.sub(data:toString(), 8, -1)	--截取choice:
	if objname == "analeptic" or objname == "peach" or objname == "amazing_grace" or objname == "ex_nihilo" or objname == "god_salvation" then
		return false
	end
	local from = findPlayerByFlag(self.room, "piaobo_usefrom_AI")
	if (objname == "iron_chain" or objname == "fudichouxin" or objname == "snatch" or objname == "dismantlement") and from and self:isFriend(from) then
		return false
	end
	if (objname == "slash" or objname == "fire_slash" or objname == "thunder_slash" or objname == "ice_slash" or objname == "archery_attack" or objname == "savage_assault" or objname == "fire_attack") and self:needToLoseHp() then
		return false
	end
	if (objname == "fire_slash" or objname == "thunder_slash" or objname == "ice_slash" or objname == "fire_attack") and from and self:isFriend(from) then
		return false
	end
	return true
end




--嘲讽
sgs.ai_chaofeng.muxiaoling_shouyindexuemei = -1

--------------------------------------------------
--血碎
--------------------------------------------------

sgs.ai_skill_cardask["@xuesui_ask"] = function(self, data, pattern, target)
	local to = findPlayerByFlag(self.room, "xuesui_target_AI")
	if not to then
		return "."
	end
	local max_card = self:getMaxCard(self.player)
	local max_card2 = self:getMaxCard(to)
	
	if not self:isFriend(to) or (self:needKongcheng(to) and to:getHandcardNum() == 1) then
		if max_card:getNumber() > 10 or (max_card2 and max_card:getNumber() > max_card2:getNumber()) or self:isFriend(to) then
			return max_card:getId()
		end
	end
	return "."
end

sgs.ai_cardneed.xuesui = function(to, card, self)
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	end
end

sgs.ai_skill_choice.xuesui = function(self, choices)
	local to = findPlayerByFlag(self.room, "xuesui_target_AI")
	if to then
		--if self:isFriend(to) and self:needToThrowArmor(to) then
		--	return "xuesui_draw"
		--end
		if self:isFriend(to) and to:isWounded() and (self:isWeak() or to:hasSkills(sgs.masochism_skill) or (to:getPhase() <= sgs.Player_Discard and self:getOverflow(to) > 0)) then
			return "xuesui_recover"
		end
		if self:isEnemy(to) and not self:canDraw(to) then
			return "xuesui_draw"
		end
		if self:isEnemy(to) and not to:isWounded() and not (self:isWeak() or to:hasSkills(sgs.masochism_skill)) then
			return "xuesui_recover"
		end
	end
	return "xuesui_draw"
end

sgs.ai_need_damaged.xuesui = function(self, attacker, player)
	if player:canPindian(attacker) and not self:isWeak(player) then
		local max_card = self:getMaxCard(player)
		local max_card2 = self:getMaxCard(attacker)
		return max_card and (max_card:getNumber() > 10 or (max_card2 and max_card:getNumber() > max_card2:getNumber()))
	end
	return false
end

--------------------------------------------------
--破印
--------------------------------------------------

sgs.ai_skill_invoke.poyin = function(self, data)	--直接用就完事了
	return true
end




--嘲讽
sgs.ai_chaofeng.zheyuanlulu_guanceduixiang = 0

--------------------------------------------------
--超元
--------------------------------------------------

sgs.ai_skill_playerchosen.chaoyuan = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "defense")
	local first, second, third, forth
	for _, p in ipairs(targetlist) do
		if self:isFriend(p) then
			if not first and not p:isAdjacentTo(self.player) then
				first = p
			end
			if not third and self:canDraw(p) and p:getCardCount(true) > 1 then
				third = p
			end
		elseif self:isEnemy(p) then
			if not second and ((self:isWeak(p) and not self:isWeak(self.player, true) and self.player:getHandcardNum() >= 3) or not self:canDraw(p)) and not self.player:inMyAttackRange(p) then
				second = p
			end
		elseif not forth and not p:isAdjacentTo(self.player) then
			forth = p
		end
		if first and second and third and forth then
			break
		end
	end
	return first or second or third or forth
end

sgs.ai_skill_cardask["@chaoyuan_recast"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local to_discard = {}
	to_discard = dimeng_discard(self, 1, cards, 3)
	return to_discard[1] or cards[1]
end

--------------------------------------------------
--焜耀
--------------------------------------------------

sgs.ai_skill_use["@@kunyao"] = function(self, prompt, method)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local can_give_cards = {}
	for _, card in ipairs(cards) do		--统计所有牌中可交出的牌
		table.insert(can_give_cards, card)
	end
	
	if #can_give_cards == 0 then
		return ""
	end
	
	local targets = sgs.SPlayerList()	--获取可以给牌的角色
	for _, to in sgs.qlist(self.room:getOtherPlayers(self.player)) do	
		if to:isAdjacentTo(self.player) and self.player:canEffect(to, "kunyao") then
			targets:append(to)
		end
	end
	
	for _, to in sgs.qlist(targets) do	--扫描可交出的牌是否有队友需要
		for _, card in ipairs(can_give_cards) do
			if self:isFriend(to) and self:needCard(to, card) then		--新函数，返回某角色是否需要某张牌（根据cardneed）
				return "#kunyao:"..card:getId()..":->"..to:objectName()
			end
		end
	end
	
	if self:needToThrowArmor() and self.player:getLostHp() > 0 and not self:needToLoseHp(self.player, self.player, false, false, true) then		--经典玩狮子
		local armor = self.player:getArmor()
		for _, card in ipairs(can_give_cards) do
			if card:getId() == armor:getId() then
				local first, second, third, forth
				for _, to in sgs.qlist(targets) do	--优先级：1.顶对面的防具 2.给没防具或者需要顶防具/玩狮子/玩装备的队友 3.随便给一个不能玩狮子或玩装备的非队友角色 4.顶队友的防具
					if self:isFriend(to) then
						if not to:getArmor() or self:needToThrowArmor(to) or (to:hasSkills(sgs.use_lion_skill.."|"..sgs.lose_equip_skill) and not self:isWeak(to)) then
							if not second then second = to end
						elseif self:isWeak(self.player, true) then
							if not forth then forth = to end
						end
					elseif not self:isFriend(to) then
						if self:isEnemy(to) and (to:getArmor() and not self:needToThrowArmor(to) and not to:hasSkills(sgs.use_lion_skill.."|"..sgs.lose_equip_skill)) then
							if not first then first = to end
						end
						if not to:hasSkills(sgs.use_lion_skill.."|"..sgs.lose_equip_skill) then
							if not third then third = to end
						end
					end
				end
				local target = first or second or third
				if target then
					return "#kunyao:"..card:getId()..":->"..target:objectName()
				end
				break
			end
		end
	end
	
	if self:getOverflow() > 0 then	--手牌溢出，则尽量给牌，但注意不要顶掉队友的装备（除非需要顶防具）
		for _, card in ipairs(can_give_cards) do
			for _, to in sgs.qlist(targets) do
				if self:isFriend(to) and self:canDraw(to) and not (card:isKindOf("EquipCard") and (to:getEquip(card:getRealCard():toEquipCard():location()) == nil or (card:isKindOf("Armor") and self:needToThrowArmor(to)) or to:hasSkills(sgs.lose_equip_skill))) then
					return "#kunyao:"..card:getId()..":->"..to:objectName()
				end
			end
		end
	end
	
	for _, card in ipairs(can_give_cards) do		--尝试交给队友基本牌/锦囊牌，或者给随便一个人杀（芬里尔觉得很赞）
		for _, to in sgs.qlist(targets) do
			if card:isKindOf("Slash") or ((card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) and self:isFriend(to) and self:canDraw(to)) then
				return "#kunyao:"..card:getId()..":->"..to:objectName()
			end
		end
	end
	
	return ""
end

sgs.ai_playerchosen_intention.kunyao = function(self, from, to)
	local intention = -10
	if (self:needKongcheng(to) and to:isKongcheng()) or hasManjuanEffect(to) then
		intention = 0
	end
	sgs.updateIntention(from, to, intention)
end




--嘲讽
sgs.ai_chaofeng.shayue_fanqietianshi = 0

--------------------------------------------------
--福音
--------------------------------------------------

sgs.ai_skill_invoke.fuyin_shayue = function(self, data)
	local target = data:toPlayer()
	
	local used_numbers = {}
	for i = 1,13,1 do
		if self.player:getMark("&fuyin_shayue->"..getNumberChar(i)) > 0 then
			table.insert(used_numbers, i)
		end
	end
	
	if self:isFriend(target) then
		return true
	else
		if #used_numbers > 7 then
			return true
		end
		if self.player:hasSkill("weiliu") --[[and self:getFinalRetrial(self.player) == 1]] then
			local can_retrial = false
			for _, card in sgs.qlist(self.player:getCards("he")) do
				if card:isKindOf("EquipCard") and not card:hasFlag("using") and self.player:getMark("&fuyin_shayue->"..getNumberChar(card:getNumber())) > 0 then
					can_retrial = true
					break
				end
			end
			if can_retrial then
				return true
			end
		end
	end
	return false
end

--------------------------------------------------
--维留
--------------------------------------------------

sgs.ai_skill_cardask["@weiliu-card"]=function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end

	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isKindOf("EquipCard") and not card:hasFlag("using") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			--self:sortByUseValue(cards, true)
			--if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
			--	return "$" .. cards[1]:getId()
			--end
		end
	elseif self:needRetrial(judge) then
		local card = sgs.Sanguosha:getCard(card_id)
		return "$" .. card_id
	end

	return "."
end

function sgs.ai_cardneed.weiliu(to, card, self)
	return card:isKindOf("EquipCard")
end

--------------------------------------------------
--豹晒（交牌部分）
--------------------------------------------------

sgs.ai_skill_discard.baoshai = function(self, discard_num, min_num, optional, include_equip)
	local toDis = {}
	local target = findPlayerByFlag(self.room, "baoshai_receiver_AI")
	if target and self:isFriend(target) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(cards, false)
		for _, card in ipairs(cards) do
			if self:needCard(target, card) then		--新函数，返回某角色是否需要某张牌（根据cardneed）
				table.insert(toDis, card:getEffectiveId())
				return toDis
			end
		end
		table.insert(toDis, cards[1]:getEffectiveId())
		return toDis
	end
	return self:askForDiscard("", discard_num, min_num, optional, include_equip)
end




--嘲讽
sgs.ai_chaofeng.nengmeifengling_lanmeiyushi = -1

--------------------------------------------------
--宵暗
--------------------------------------------------

sgs.ai_skill_playerchosen.xiaoan = function(self, targetlist)
	local base_value = 0	--最低收益门槛，其中1牌价值为10
	return self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Thunder, targetlist, true, base_value, false)
end

function sgs.ai_cardneed.xiaoan(to, card, self)
	return card:isKindOf("Jink")
end




--嘲讽
sgs.ai_chaofeng.xiaoxixiaotao_eniac = -2

--------------------------------------------------
--联袂
--------------------------------------------------

sgs.ai_skill_playerchosen.lianmei = function(self, targetlist)
	local targets = self:findPlayerToDiscard("he", false, true, targetlist, true, self.player)
	if #targets > 0 then
		for _, p in ipairs(targets) do
			if not self:isFriend(p) then
				return p
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.lianmei = function(self, from, to)
	local intention = 10
	if not self:needKongcheng(to) and not to:hasSkills(sgs.lose_card_skills) and not to:hasSkills(sgs.need_equip_skill) then
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_choicemade_filter.cardChosen["lianmei"] = sgs.ai_choicemade_filter.cardChosen.dismantlement

sgs.ai_need_damaged.lianmei = function(self, attacker, player)
	if not self:isWeak(player) or (self:getAllPeachNum(player) > 0 and self:getOverflow() < 2) then
		return true
	end
	return false
end

--------------------------------------------------
--维护
--------------------------------------------------

local weihuvs_skill = {}
weihuvs_skill.name = "weihuvs"
table.insert(sgs.ai_skills,weihuvs_skill)
weihuvs_skill.getTurnUseCard=function(self)
	if self:needBear() then return end
	if self.player:getKingdom() == "xuyanshe" and self.player:getRole() ~= "lord" and self.room:getLord() and self:isFriend(self.room:getLord()) and self.room:getLord():getLostHp() > 0 and self.player:getCardCount(true) >= 2 and self.player:usedTimes("#weihuvs") < 1 then
		return sgs.Card_Parse("#weihuvs:.:")
	end
end

sgs.ai_skill_use_func["#weihuvs"] = function(card, use, self)
	local lord = self.room:getLord()
	if lord and lord:isAlive() and lord:getLostHp() > 0 then
		if self:getOverflow() > 0 or self:needToThrowArmor() or self:isWeak(lord) then
			local cards = self.player:getCards("he")
			cards = sgs.QList2Table(cards)
			for _, card in ipairs(cards) do
				if card:isKindOf("Peach") then
					table.removeOne(cards, card)
				end
			end
			if #cards >= 2 then
				local ids = dimeng_discard(self, 2, cards)
				if use.to then
					use.to:append(lord)
				end
				card_str = "#weihuvs:"..table.concat(ids, "+")..":->"..lord:objectName()
				use.card = sgs.Card_Parse(card_str)
			end
		end
	end
end

sgs.ai_use_value.weihuvs = 2.5
sgs.ai_use_priority.weihuvs = 9
sgs.ai_card_intention.weihuvs = -10

sgs.ai_card_intention.weihuvs = function(self, card, from, tos)
    local to = tos[1]
    sgs.updateIntention(from, to, -10)
end




--嘲讽
sgs.ai_chaofeng.qihaiyouxian_zhuangzhilingyun = -2

--------------------------------------------------
--幽蓝
--------------------------------------------------

function sgs.ai_cardneed.youlan(to, card, self)
	return card:isKindOf("TrickCard") and card:isDamageCard()
end




--嘲讽
sgs.ai_chaofeng.hanazono_serena_if = 2

--------------------------------------------------
--酣歌（冰火歌会）
--------------------------------------------------

sgs.ai_skill_playerchosen.hange_if = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "hp")
	
	for _, p in ipairs(targetlist) do
		if self:isFriend(p) and p:getLostHp() > 0 and not self:needToLoseHp(p, self.player, false, false, true) then
			return p
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.hange_if = function(self, from, to)
	local intention = -10
	sgs.updateIntention(from, to, intention)
end




--嘲讽
sgs.ai_chaofeng.xiaoc_cheshenchuanshuo = 2

--------------------------------------------------
--疾冲
--------------------------------------------------

local jichong_skill={}
jichong_skill.name="jichong"
table.insert(sgs.ai_skills,jichong_skill)
jichong_skill.getTurnUseCard=function(self,inclusive)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local card

	self:sortByUseValue(cards,true)

	local has_equip = {false, false, false, false, false}

	for _,acard in ipairs(cards)  do
		if acard:isKindOf("EquipCard") and not (acard:getSuit() == sgs.Card_Heart) then has_equip[acard:getRealCard():toEquipCard():location()+1] = true end
	end

	for _,acard in ipairs(cards)  do
		if (acard:getSuit() == sgs.Card_Heart) and ((self:getUseValue(acard)<sgs.ai_use_value.Indulgence) or inclusive) then
			local shouldUse=true

			if acard:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(acard) and not has_equip[2] and self:evaluateArmor() > 0 then shouldUse = false
				end
			end

			--if acard:isKindOf("EquipCard") then		--装备哪有乐重要
			--	local index = acard:getRealCard():toEquipCard():location()
			--	if not self.player:getEquip(index) then shouldUse = false
			--	elseif self.player:hasEquip(acard) and not has_equip[index+1] then shouldUse = false
			--	end
			--end

			if shouldUse then
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("indulgence:jichong[heart:%s]=%d"):format(number, card_id)
	local indulgence = sgs.Card_Parse(card_str)
	assert(indulgence)
	return indulgence
end

function sgs.ai_cardneed.jichong(to, card)
	return card:getSuit() == sgs.Card_Heart
end

sgs.jichong_suit_value = {
	heart = 3.9
}

--------------------------------------------------
--目涩
--------------------------------------------------

sgs.ai_skill_invoke.muse = function(self, data)
	local objname = string.sub(data:toString(), 8, -1)	--截取choice:后面的部分(即player:objectName())
	local to = findPlayerByObjName(self.room, objname)
	if to and not self:isEquipLocking(to) then
		if self:isFriend(to) and (self:needToThrowArmor(to) or to:hasSkills(sgs.lose_equip_skill)) then
			return true
		elseif not self:isFriend(to) and not self:needToThrowArmor(to) and not to:hasSkills(sgs.lose_equip_skill) and (to:getEquips():length() >= self.player:getHandcardNum()-1 or self.player:getMark("muse_from_"..to:objectName()) > 0) then
			return true
		end
	end
	return false
end

sgs.ai_skill_discard.muse = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("", discard_num, min_num, optional, include_equip)
end



--嘲讽
sgs.ai_chaofeng.jinghua_if = -2

--------------------------------------------------
--创世
--------------------------------------------------

sgs.ai_skill_playerchosen.chuangshi = function(self, targetlist)
	local target = self:findPlayerToDraw(true, 2)
	targetlist = sgs.QList2Table(targetlist)
	for _, p in ipairs(targetlist) do
		if p:objectName() == target:objectName() then
			return p
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.chuangshi = function(self, from, to)
	local intention = -10
	sgs.updateIntention(from, to, intention)
end

sgs.ai_need_damaged.chuangshi = function(self, attacker, player)
	if not self:isWeak(player) or self:getAllPeachNum(player) > 0 then
		return true
	end
	return false
end

sgs.ai_skill_choice.chuangshi = function(self, choices)
	local data = self.player:getTag("chuangshi")
	local damage = data:toDamage()
    local card_ids = {}
	for _,id in sgs.qlist(damage.card:getSubcards()) do
		if self.room:getCardPlace(id) == sgs.Player_PlaceTable then
			table.insert(card_ids, id)
		end
	end
	
	local up, bottom = self:askForGuanxing(card_ids, sgs.Room_GuanxingBothSides, -1, -1)
	if #up > 0 then
		return "drawPileTop"
	end
	return "drawPileEnd"
end



--嘲讽
sgs.ai_chaofeng.xiachuanyueyue_if = 1

--------------------------------------------------
--散礼
--------------------------------------------------

sgs.ai_skill_askforyiji["sanli"] = function(self, card_ids)
	local move_skill = self.player:getTag("QingjianCurrentMoveSkill"):toString()
	if --[[move_skill == "rende" or move_skill == "nosrende" or]] move_skill == "qingjian" then return nil, -1 end
	
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end

	local new_friends = {}
	local CanKeep
	for _, friend in ipairs(self.friends) do
		if self:canDraw(friend) and
		((friend:getPhase() == sgs.Player_NotActive and not (self:willSkipPlayPhase(friend) and self:getOverflow(friend) > 0)) or (friend:getPhase() ~= sgs.Player_NotActive and self:getOverflow(friend) <= 0)) and
		(friend:getHandcardNum() >= 4) then
			if friend:objectName() == self.player:objectName() then
				CanKeep = true
			else
				table.insert(new_friends, friend)
			end
		end
	end

	if #new_friends > 0 then
		local card, target = self:getCardNeedPlayer(cards, false)
		if card and target then
			for _, friend in ipairs(new_friends) do
				if target:objectName() == friend:objectName() then
					return friend, card:getEffectiveId()
				end
			end
		end
		self:sort(new_friends, "defense")
		self:sortByKeepValue(cards, true)
		if self:hasSkills(sgs.notActive_cardneed_skill, new_friends[1]) or (self:hasSkills(sgs.Active_cardneed_skill, new_friends[1]) and not self:willSkipPlayPhase(new_friends[1])) or
			(--[[(self.player:getMark("@sanli_mark") < 2) or]] (self.player:getPhase() ~= sgs.Player_NotActive and self:getOverflow() > 0)) then
			return new_friends[1], cards[1]:getEffectiveId()
		end
	elseif CanKeep --[[and not (self.player:getMark("@sanli_mark") < 2 and #self.friends_noself > 0)]] then
		return nil, -1
	else
		local other = {}
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) and not self:isLihunTarget(player) then
				table.insert(other, player)
			end
		end
		if #other > 0 and #card_ids > 0 then
			return other[math.random(1, #other)], card_ids[math.random(1, #card_ids)]
		end
	end
end

sgs.ai_cardneed.sanli = function(to, card, self)
	return not self.room:getCurrent():hasFlag("sanli_used_"..self.player:objectName())
end

--------------------------------------------------
--酣饮
--------------------------------------------------

function sgs.ai_cardsview.hanyin(self, class_name, player)
	if class_name == "Analeptic" then
		if player:hasSkill("hanyin") and player:getMark("&hanyin+used+_lun") == 0 and player:getHandcardNum() <= 1 then
			return ("analeptic:hanyin[no_suit:0]=.")
		end
	end
end



--嘲讽
sgs.ai_chaofeng.bingtang_if = 1

--------------------------------------------------
--执儡
--------------------------------------------------

sgs.ai_skill_invoke.zhilei = function(self, data)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	
	local target_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:hasFlag("zhilei") then
			table.insert(target_cards, cd)
		end
	end
	if #target_cards == 0 then
		return false
	end
	
	self:sortByUseValue(target_cards, true)
	target_cards = sgs.reverse(target_cards)
	
	for _,target_card in ipairs(target_cards) do
		if target_card:targetFixed() then
			if target_card:isKindOf("EquipCard") then
				local equip_index = target_card:getRealCard():toEquipCard():location()
				if (self.player:getEquip(equip_index) == nil or self.player:getHandcardNum() > self:getBestKeepHandcardNum()) and self.player:hasEquipArea(equip_index) then
					return true
				end
			end
			if target_card:isKindOf("Armor") then
				local equip_index = target_card:getRealCard():toEquipCard():location()
				if self.player:getEquip(equip_index) ~= nil and self.player:hasEquipArea(equip_index) and self:needToThrowArmor() then
					return true
				end
			end
			if target_card:isKindOf("SavageAssault") then
				local savage_assault = sgs.Sanguosha:cloneCard("SavageAssault")
				if self:getAoeValue(savage_assault) > 0 then
					savage_assault:deleteLater()
					return true
				end
				savage_assault:deleteLater()
			end
			if target_card:isKindOf("ArcheryAttack") then
				local archery_attack = sgs.Sanguosha:cloneCard("ArcheryAttack")
				if self:getAoeValue(archery_attack) > 0 then
					archery_attack:deleteLater()
					return true
				end
				archery_attack:deleteLater()
			end
			if target_card:isKindOf("Peach") and self.player:getLostHp() > 0 then
				return true
			end
			if target_card:isKindOf("ExNihilo") then
				return true
			end
		elseif target_card:isKindOf("TrickCard") then
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(target_card, dummyuse)
			if not dummyuse.to:isEmpty() then
				return true
			end
		elseif target_card:isKindOf("Slash") then
			local slash = target_card
			for _,enemy in ipairs(self.enemies) do	--yun
				if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) and self.player:canSlash(enemy, slash, true) then
					return true
				end
			end
		end
		if not self:canDraw(self.player) then
			return true
		end
	end
	return false
end

function doZhilei(room, player)	--由于执儡的触发和转换是在about_to_use内完成，且ai与玩家的使用路径不同，故需要在return前手动触发并转换
	local logg = sgs.LogMessage()
	logg.from = player
	logg.type = "#InvokeSkill"
	logg.arg = "zhilei"
	room:sendLog(logg)	--显示技能发动提示信息
	room:notifySkillInvoked(player, "zhilei")	--在武将牌上显示技能名
	room:setChangeSkillState(player, "zhilei", Ternary(player:getChangeSkillState("zhilei") <= 1, 2, 1))
	player:setFlags("zhilei_used")
end

sgs.ai_skill_use["@@zhilei"] = function(self, prompt, method)
	self:updatePlayers()
	if not self:askForSkillInvoke("zhilei", nil) then
		return "."
	end
	
	local target_cards = {}
	for _, cd in sgs.qlist(self.player:getHandcards()) do
		if cd:hasFlag("zhilei") then
			table.insert(target_cards, cd)
		end
	end
	if #target_cards == 0 then return end
	
	self:sortByUseValue(target_cards, true)
	target_cards = sgs.reverse(target_cards)
	
	for _,target_card in ipairs(target_cards) do
		if target_card:targetFixed() then
			doZhilei(self.room, self.player)
			return target_card:toString()
		else
			if target_card:isKindOf("Slash") then	--yun
				local to = self:findPlayerToSlash(false, target_card, nil, true)		--距离限制、卡牌、角色限制、必须选择
				doZhilei(self.room, self.player)
				return target_card:toString() .. "->" .. to:objectName()
			end
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(target_card, dummyuse)
			local targets = {}
			if not dummyuse.to:isEmpty() then
				for _, p in sgs.qlist(dummyuse.to) do
					table.insert(targets, p:objectName())
				end
				doZhilei(self.room, self.player)
				return target_card:toString() .. "->" .. table.concat(targets, "+")
			else		--强制选择随机目标
				local targets_list = sgs.PlayerList()
				for _, target in sgs.qlist(self.room:getAlivePlayers()) do
					targets_list:append(target)
				end
				local targets = {}
				for _,p in sgs.qlist(self.room:getAlivePlayers()) do
					if target_card:targetFilter(targets_list, p, self.player) and not sgs.Self:isProhibited(p, target_card) then
						table.insert(targets, p:objectName())
					end
				end
				if #targets > 0 then
					doZhilei(self.room, self.player)
					return target_card:toString() .. "->" .. targets[math.random(1,#targets)]
				end
			end
		end
	end
	return "."
end

--------------------------------------------------
--旧魇
--------------------------------------------------

sgs.ai_skill_invoke.jiuyan = function(self, data)
	local target = data:toPlayer()
	local dis_table = self:findPlayerToDiscard("he", true, true, nil, true, self.player)
	if dis_table and table.contains(dis_table, target) then
		return true
	end
	return false
end

sgs.ai_skill_choice.jiuyan = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if table.contains(items, "jiuyan_discard") then
			return "jiuyan_discard"
		end
		if table.contains(items, "jiuyan_damage") then
			return "jiuyan_damage"
		end
	end
end

sgs.ai_need_damaged.jiuyan = function(self, attacker, player)
	if (not self:isWeak(player) or self:getAllPeachNum(player) > 0) and attacker and attacker:isAlive() and self:isEnemy(attacker, player) and (self:getDangerousCard(attacker) ~= nil or self:getValuableCard(attacker) ~= nil) then
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.yuzuojinuonuo_geiniyiquan = 2

--------------------------------------------------
--嗔怪
--------------------------------------------------

sgs.ai_skill_invoke.chenguai = function(self, data)
	local _data = self.player:getTag("chenguai")
	local use = _data:toCardUse()
	local target = self.room:getCurrent()
	local card = use.card
	local locked_card = 0
	local delayedtricks = 0
	for _, cd in sgs.qlist(target:getHandcards()) do
		if cd:getTypeId() == card:getTypeId() then
			locked_card = locked_card + 1
		end
		if (cd:isKindOf("Indulgence") or cd:isKindOf("SupplyShortage")) then
			delayedtricks = delayedtricks + 1
		end
	end
	if self:isEnemy(target) then
		if not card:isKindOf("DelayedTrick") and delayedtricks > 0 then	--憋着等对面用兵乐
			return false
		end
		if card:isKindOf("DelayedTrick") then
			return true
		end
		if card:isKindOf("TrickCard") and target:hasSkills("xianwei|diyin|yunyao|mingxian|fengjin") then	--特化封锦囊
			return true
		elseif card:isKindOf("EquipCard") and (target:hasSkills("motiao") or locked_card > 0) then
			return true
		elseif card:isKindOf("Slash") and locked_card > 0 and self:hasCrossbowEffect(target) then
			return true
		end
		if card:isKindOf("Analeptic") then	--封酒
			return true
		end
		if locked_card > 2 and not (card:isKindOf("Peach") or card:isKindOf("ExNihilo") or card:isKindOf("Snatch")) and card:subcardsLength() <= 1 then
			return true
		end
	elseif self:isFriend(target) then
		if card:isKindOf("DelayedTrick") or (card:isKindOf("EquipCard") and not card:isKindOf("Armor")) then
			return false
		end
		if (locked_card == 0 and self:getOverflow(target) == 0) or (card:subcardsLength() > 1 and locked_card < 4) or (card:isKindOf("Armor") and self:needToThrowArmor(target) and locked_card < 2) then
			return true
		end
		if locked_card < 2 and (card:isKindOf("Peach") or card:isKindOf("ExNihilo") or card:isKindOf("Snatch")) then
			return true
		end
	end
	
	return false
end

--------------------------------------------------
--兔拳
--------------------------------------------------

sgs.ai_view_as.tuquan = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("Slash") and card_place == sgs.Player_PlaceHand then
		return ("jink:tuquan[%s:%s]=%d"):format(suit, number, card_id)
	end
end




--嘲讽
sgs.ai_chaofeng.huajianxili_sorry = 1

--------------------------------------------------
--索求
--------------------------------------------------

local suoqiu_skill = {}
suoqiu_skill.name = "suoqiu"
table.insert(sgs.ai_skills, suoqiu_skill)
suoqiu_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#suoqiu") >= 1 and not self.player:isKongcheng() then return end
	return sgs.Card_Parse("#suoqiu:.:")
end
sgs.ai_skill_use_func["#suoqiu"] = function(card, use, self)
	local cards = {}
	for _,card in sgs.qlist(self.player:getCards("h")) do
		if card:isRed() then
			table.insert(cards, card)
		end
	end
	local ids = dimeng_discard(self, 1, cards, 3)
	local cost_card
	if #ids > 0 then
		cost_card = ids[1]
	else
		return
	end
	
	local targets = sgs.SPlayerList()
	self:sort(self.enemies, "defense")
	for _, vic in ipairs(self.enemies) do
		if not vic:isKongcheng() and SkillCanTarget(vic, self.player, "suoqiu") and self.player:canEffect(vic, "suoqiu") then
			targets:append(vic)
		end
	end
	self:sort(self.friends_noself, "defense")
	for _, vic in ipairs(self.friends_noself) do
		if not vic:isKongcheng() and SkillCanTarget(vic, self.player, "suoqiu") and self.player:canEffect(vic, "suoqiu") then
			targets:append(vic)
		end
	end
	if not targets:isEmpty() then
		local first, second, third, forth
		
		for _, to in sgs.qlist(targets) do
			if self:isEnemy(to) then
				if not second and self.player:canSeeHandcard(to) then		--手牌可见
					second = to
				elseif not third and getCardsNum("VisibleCard", to, self.player) > 0 then	--有明牌
					third = to
				end
			elseif self:isFriend(to) and to:getLostHp() > 0 and not self:needToLoseHp(to, self.player, false, false, true) and (self.player:canSeeHandcard(to) or getCardsNum("VisibleCard", to, self.player) > 0) then
				if not first and self:isWeak(to) then
					first = to
				elseif not forth then
					forth = to
				end
			end
		end
		
		local target = first or second or third or forth	--or连接多个操作数时，表达式的返回值就是从左到右第一个不为假的值，若全部操作数值都为假，则表达式的返回值为最后一个操作数
		if target then
			self.suoqiu_card = nil
			
			local handcards = sgs.QList2Table(target:getHandcards())
			local can_see = self.player:canSeeHandcard(target)
			if #handcards > 1 then
				if self:isFriend(target) then		--按价值全部排序，价值类别由是否为友方决定
					self:sortByKeepValue(handcards)			--keep value从低到高
				else
					self:sortByUseValue(handcards, false)	--use value从高到低
					handcards = sgs.reverse(handcards)		--反转为从高到低
				end
			end
			for _, c in ipairs(handcards) do
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
				if can_see or c:hasFlag("visible") or c:hasFlag(flag) then
					self.suoqiu_card = c
					break
				end
			end
			
			if use.to then
				use.to:append(target)
			end
			card_str = "#suoqiu:"..cost_card..":->"..target:objectName()
			use.card = sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_value["suoqiu"] = 1 --卡牌使用价值
sgs.ai_use_priority["suoqiu"] = 7.9 --卡牌使用优先级

sgs.ai_skill_cardask["@suoqiu_give"] = function(self, data, pattern, target)
	local card_name = data:toString()
	
	local cards = {}
	for _,cd in sgs.qlist(self.player:getHandcards()) do
		if cd:objectName() == card_name then
			table.insert(cards, cd)
		end
	end
	self:sortByKeepValue(cards)
	return "$"..cards[1]:getEffectiveId()
end

sgs.ai_skill_invoke.suoqiu = function(self, data)
	local objname = string.sub(data:toString(), 8, -1)	--截取choice:后面的部分(即player:objectName())
	local to = findPlayerByObjName(self.room, objname)
	if to and self:isFriend(to) and not self:needToLoseHp(to, self.player, false, false, true) then
		return true
	end
	return false
end

sgs.ai_skill_choice.suoqiu = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if self.suoqiu_card then
			for _, item in ipairs(items) do
				if self.suoqiu_card:isKindOf(item) then
					return item
				end
			end
		end
		
		--默认顺序
		if table.contains(items, "BasicCard") then
			return "BasicCard"
		elseif table.contains(items, "TrickCard") then
			return "TrickCard"
		elseif table.contains(items, "EquipCard") then
			return "EquipCard"
		elseif table.contains(items, "Armor") then
			return "Armor"
		elseif table.contains(items, "Weapon") then
			return "Weapon"
		elseif table.contains(items, "Horse") then
			return "Horse"
		elseif table.contains(items, "Treasure") then
			return "Treasure"
		end
	end
end

sgs.ai_skill_askforag["suoqiu"] = function(self, card_ids)
	if self.suoqiu_card then
		for _,id in ipairs(card_ids) do
			if sgs.Sanguosha:getCard(id):objectName() == self.suoqiu_card:objectName() then
				self.suoqiu_card = nil
				return id
			end
		end
	end
	return card_ids[1]
end

sgs.ai_cardneed.suoqiu = function(to, card, self)
	return to:getHandcardNum() <= 3 and card:isRed()
end




--嘲讽
sgs.ai_chaofeng.buding_lichilingya = 1

--------------------------------------------------
--无忌
--------------------------------------------------

sgs.ai_skill_playerchosen.wuji_buding = function(self, targetlist)
	targetlist = sgs.QList2Table(targetlist)
	self:sort(targetlist, "defense")
	
	return self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, targetlist, true, 0, false) or targetlist[math.random(1, #targetlist)]
end

sgs.ai_cardneed.wuji_buding = function(to, card)
	local count = to:getMark("wuji_buding_suit_heart") + to:getMark("wuji_buding_suit_diamond") + to:getMark("wuji_buding_suit_spade") + to:getMark("wuji_buding_suit_club")
	if count >= 2 then
		return card:getSuit() >= 0 and card:getSuit() <= 3 and to:getMark("wuji_buding_suit_"..card:getSuitString()) == 0
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.xiaonai_zhinengzhushou = 1

--------------------------------------------------
--全能！
--------------------------------------------------

function generateAllCardObjectNameTablePatterns()
	return {"slash","fire_slash","thunder_slash","ice_slash","jink","peach","analeptic","ex_nihilo","amazing_grace","god_salvation","archery_attack","savage_assault","collateral","dismantlement","snatch","duel","fire_attack","iron_chain","fudichouxin","nullification"}
end

local quanneng_xiaonai_skill = {}
quanneng_xiaonai_skill.name = "quanneng_xiaonai"
table.insert(sgs.ai_skills, quanneng_xiaonai_skill)
quanneng_xiaonai_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("AI_do_not_invoke_quanneng_xiaonai_lun") > 0 or self.player:hasFlag("Global_QuannengFailed") then return end
	local patterns = generateAllCardObjectNameTablePatterns()
	local choices = {}
	for _, name in ipairs(patterns) do
		local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		if self.player:canUse(poi) --[[and self.player:getMark("quanneng_xiaonai"..name) == 0]] then
			table.insert(choices, name)
		end
		poi:deleteLater()
	end
	if next(choices) and self.player:getMark("&quanneng_xiaonai_used+_lun") == 0 then
		local _data = sgs.QVariant()
		--local result = self:askForChoice("quanneng_xiaonai", table.concat(choices, "+"), _data)
		--if result and result ~= "cancel" then
			return sgs.Card_Parse("#quanneng_xiaonai:.:")
		--end
	end
end

sgs.ai_skill_use_func["#quanneng_xiaonai"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, true)
	local useable_cards = {}
	--if self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:isWounded() then
	--	table.insert(useable_cards, self.player:getArmor())
	--end
	--if self.player:getPile("wooden_ox"):length() > 0 then
	--	for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
	--		if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
	--			table.insert(handcards, sgs.Sanguosha:getCard(id))
	--		end
	--	end
	--end
	for _,c in ipairs(handcards) do
		if c:getSuit() ~= sgs.Card_Heart
		and not c:isKindOf("Peach")
		and not c:isKindOf("Analeptic")
		and not (c:isKindOf("Analeptic") and self:getCardsNum("Analeptic") == 1 and self.player:getHp() <= 1)
		and not (c:isKindOf("Jink") and self:getCardsNum("Jink") == 1)
		and not c:isKindOf("Nullification")
		and not c:isKindOf("SavageAssault")
		and not c:isKindOf("ArcheryAttack")
		and not c:isKindOf("Duel")
		and not c:isKindOf("Armor")
		and not c:isKindOf("DefensiveHorse")
		then
			table.insert(useable_cards, c)
		end
	end
	if #useable_cards == 0 then return end
	if useable_cards[1]:hasFlag("xiahui") then return end
	--self.room:setTag("ai_quanneng_xiaonai_card_id", sgs.QVariant(useable_cards[1]:getEffectiveId()))
	if not self.ai_quanneng_xiaonai_card_id then
		self.ai_quanneng_xiaonai_card_id = -1	--先确定此变量为int类型
	end
	self.ai_quanneng_xiaonai_card_id = useable_cards[1]:getEffectiveId()
	local card_str = string.format("#quanneng_xiaonai:%s:", useable_cards[1]:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
end

sgs.ai_use_priority["quanneng_xiaonai"] = 0
sgs.ai_use_value["quanneng_xiaonai"] = 3

sgs.ai_skill_choice["quanneng_xiaonai"] = function(self, choices, data)
	--local ai_quanneng_xiaonai_card_id = self.room:getTag("ai_quanneng_xiaonai_card_id"):toInt()
	--self.room:removeTag("ai_quanneng_xiaonai_card_id")
	if not self.ai_quanneng_xiaonai_card_id or self.ai_quanneng_xiaonai_card_id == -1 then return "cancel" end
	local ai_quanneng_xiaonai_card_id = self.ai_quanneng_xiaonai_card_id
	self.ai_quanneng_xiaonai_card_id = -1
	
	if not self.ai_quanneng_xiaonai_card_name then
		self.ai_quanneng_xiaonai_card_name = ""	--先确定此变量为字符串
	end
	
	local quanneng_xiaonai_vs_card = {}
	local types = {"BasicCard", "TrickCard", "EquipCard"}
	local suit = sgs.Sanguosha:getCard(ai_quanneng_xiaonai_card_id):getSuit()
	local number = sgs.Sanguosha:getCard(ai_quanneng_xiaonai_card_id):getNumber()
	local items = choices:split("+")
	for _,card_name in ipairs(items) do
		if card_name ~= "cancel" then
			local use_card = sgs.Sanguosha:cloneCard(card_name, suit, number)
			table.insert(quanneng_xiaonai_vs_card, use_card)
			use_card:deleteLater()
		end
	end
	self:sortByUsePriority(quanneng_xiaonai_vs_card)
	for _,c in ipairs(quanneng_xiaonai_vs_card) do
		if table.contains(items, c:objectName()) then
			if c:targetFixed() then
				if c:isKindOf("Peach") and self.player:isWounded() and self.player:getHp() <= 2 then
					self.ai_quanneng_xiaonai_card_name = c:objectName()
					self.ai_quanneng_xiaonai_card_id = ai_quanneng_xiaonai_card_id
					return c:objectName()
				end
				if c:isKindOf("ExNihilo") and self.player:getHandcardNum() <= 2 then
					self.ai_quanneng_xiaonai_card_name = c:objectName()
					self.ai_quanneng_xiaonai_card_id = ai_quanneng_xiaonai_card_id
					return c:objectName()
				end
				if c:isKindOf("SavageAssault") then
					if self:getAoeValue(c) > 0 then
						self.ai_quanneng_xiaonai_card_name = c:objectName()
						self.ai_quanneng_xiaonai_card_id = ai_quanneng_xiaonai_card_id
						return c:objectName()
					end
				end
				if c:isKindOf("ArcheryAttack") then
					if self:getAoeValue(c) > 0 then
						self.ai_quanneng_xiaonai_card_name = c:objectName()
						self.ai_quanneng_xiaonai_card_id = ai_quanneng_xiaonai_card_id
						return c:objectName()
					end
				end
				if c:isKindOf("AmazingGrace") then
					local profit_count = 0
					for _, friend in ipairs(self.friends) do
						if self:canDraw(friend) then
							profit_count = profit_count + 1
						end
					end
					for _, enemy in ipairs(self.enemies) do
						if self:canDraw(enemy) then
							profit_count = profit_count - 1
						end
					end
					if profit_count >= 3 then
						self.ai_quanneng_xiaonai_card_name = c:objectName()
						self.ai_quanneng_xiaonai_card_id = ai_quanneng_xiaonai_card_id
						return c:objectName()
					end
				end
				if c:isKindOf("GodSalvation") then
					if self:willUseGodSalvation(c) then
						self.ai_quanneng_xiaonai_card_name = c:objectName()
						self.ai_quanneng_xiaonai_card_id = ai_quanneng_xiaonai_card_id
						return c:objectName()
					end
				end
				if c:isKindOf("Analeptic") then
					for _, slash in ipairs(self:getCards("Slash")) do
						if slash:isKindOf("NatureSlash") and slash:isAvailable(self.player) and slash:getEffectiveId() ~= ai_quanneng_xiaonai_card_id then
							local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
							self:useBasicCard(slash, dummyuse)
							if not dummyuse.to:isEmpty() then
								for _, p in sgs.qlist(dummyuse.to) do
									if self:shouldUseAnaleptic(p, slash) then
										self.ai_quanneng_xiaonai_card_name = c:objectName()
										self.ai_quanneng_xiaonai_card_id = ai_quanneng_xiaonai_card_id
										return c:objectName()
									end
								end
							end
						end
					end
				end
			else
				if c:isKindOf("NatureSlash") and self:getCardsNum("NatureSlash") == 0 then
					if c:isKindOf("FireSlash") or c:isKindOf("ThunderSlash") or c:isKindOf("IceSlash") then
						local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
						self:useBasicCard(c, dummyuse)
						local targets = {}
						if not dummyuse.to:isEmpty() then
							for _, p in sgs.qlist(dummyuse.to) do
								if p:isChained() then
									--self.room:setTag("ai_quanneng_xiaonai_card_name", sgs.QVariant(c:objectName()))
									--self.room:setTag("ai_quanneng_xiaonai_card_id", sgs.QVariant(ai_quanneng_xiaonai_card_id))
									self.ai_quanneng_xiaonai_card_name = c:objectName()
									self.ai_quanneng_xiaonai_card_id = ai_quanneng_xiaonai_card_id
									return c:objectName()
								end
							end
						end
					end
				end
				--if use_card:isNDTrick() then
				if c:isKindOf("TrickCard") and not c:isKindOf("Collateral") then
					local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
					self:useTrickCard(c, dummyuse)
					local targets = {}
					if not dummyuse.to:isEmpty() then
						for _, p in sgs.qlist(dummyuse.to) do
							if p:getHp() <= 2 and p:getCards("he"):length() <= 2 and p:getHandcardNum() <= 1 then
								--self.room:setTag("ai_quanneng_xiaonai_card_name", sgs.QVariant(c:objectName()))
								--self.room:setTag("ai_quanneng_xiaonai_card_id", sgs.QVariant(ai_quanneng_xiaonai_card_id))
								self.ai_quanneng_xiaonai_card_name = c:objectName()
								self.ai_quanneng_xiaonai_card_id = ai_quanneng_xiaonai_card_id
								return c:objectName()
							end
						end
					end
				end
			end
		end
	end
	
	self.room:addPlayerMark(self.player, "AI_do_not_invoke_quanneng_xiaonai_lun")
	return "cancel"
end

sgs.ai_skill_askforag["quanneng_xiaonai"] = function(self, card_ids)	--新式泛转化选牌（五谷框）
	local choices = {}
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(choices, card:objectName())
	end
	local _data = sgs.QVariant()
	local result = self:askForChoice("quanneng_xiaonai", table.concat(choices, "+"), _data)
	if result and result ~= "cancel" then
		for _,id in ipairs(card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if card:objectName() == result then
				self.room:setTag("ai_quanneng_xiaonai_card_name", sgs.QVariant(card:objectName()))
				return id
			end
		end
	end
	return -1
end

sgs.ai_skill_use["@@quanneng_xiaonai"] = function(self, prompt, method)
	if not self.ai_quanneng_xiaonai_card_id or self.ai_quanneng_xiaonai_card_id == -1 then return "." end
	if not self.ai_quanneng_xiaonai_card_name or self.ai_quanneng_xiaonai_card_name == "" then return "." end
	
	--local ai_quanneng_xiaonai_card_name = self.room:getTag("ai_quanneng_xiaonai_card_name"):toString()
	--self.room:removeTag("ai_quanneng_xiaonai_card_name")
	--local ai_quanneng_xiaonai_card_id = self.room:getTag("ai_quanneng_xiaonai_card_id"):toInt()
	--self.room:removeTag("ai_quanneng_xiaonai_card_id")
	local ai_quanneng_xiaonai_card_name = self.ai_quanneng_xiaonai_card_name
	self.ai_quanneng_xiaonai_card_name = ""
	local ai_quanneng_xiaonai_card_id = self.ai_quanneng_xiaonai_card_id
	self.ai_quanneng_xiaonai_card_id = -1
	
	local quanneng_xiaonai_use_card = sgs.Sanguosha:getCard(ai_quanneng_xiaonai_card_id)
	local suit = quanneng_xiaonai_use_card:getSuitString()
	local number = quanneng_xiaonai_use_card:getNumberString()
	local use_card = sgs.Sanguosha:cloneCard(ai_quanneng_xiaonai_card_name, sgs.Card_NoSuit, -1)
	use_card:setSkillName("quanneng_xiaonai")
	use_card:addSubcard(ai_quanneng_xiaonai_card_id)
	
	if (use_card:targetFixed() and self:willUse(self.player, use_card)) then
		return use_card:toString()
	else
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		if use_card:isKindOf("TrickCard") then
			self:useTrickCard(use_card, dummyuse)
		elseif use_card:isKindOf("BasicCard") then
			self:useBasicCard(use_card, dummyuse)
		end
		local targets = {}
		if not dummyuse.to:isEmpty() then
			for _, p in sgs.qlist(dummyuse.to) do
				table.insert(targets, p:objectName())
			end
			if #targets > 0 then
				return use_card:toString() .. "->" .. table.concat(targets, "+")
			end
		end
	end
	
	self.room:addPlayerMark(self.player, "AI_do_not_invoke_quanneng_xiaonai_lun")
	return "."
end

sgs.ai_cardsview["quanneng_xiaonai"] = function(self, class_name, player)
	--if sgs.ai_role[self.player:objectName()] == "neutral" then return end
	if self.player:getMark("&quanneng_xiaonai_used+_lun") > 0 then return end
	--if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	--for _, p in sgs.qlist(self.room:getAllPlayers()) do
	--	if sgs.GetConfig("quanneng_xiaonai_down", true) and (p:hasFlag("Global_Dying") or self.player:hasFlag("Global_Dying")) then return end
	--end
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["Nullification"] = "nullification",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash", ["IceSlash"] = "ice_slash"
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local no_have = true
	local cards = player:getCards("h")
	--for _, id in sgs.qlist(player:getPile("wooden_ox")) do
	--	cards:prepend(sgs.Sanguosha:getCard(id))
	--end
	for _,c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			no_have = false
			break
		end
	end
	if not no_have or player:getMark("&quanneng_xiaonai_used+_lun") ~= 0 then return end
	if class_name == "Peach" and player:getMark("Global_PreventPeach") > 0 then return end
	local canuse_cards = {}
	for _,card in sgs.qlist(cards) do
		if card:getSuit() ~= sgs.Card_Heart then
			table.insert(canuse_cards, card)
		end
	end
	--canuse_cards = sgs.QList2Table(canuse_cards)
	--if player:getPile("wooden_ox"):length() > 0 then
	--	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
	--		if not sgs.Sanguosha:getCard(id):isKindOf("Peach") then
	--			cards[1] = sgs.Sanguosha:getCard(id)
	--		end
	--	end
	--end
	if #canuse_cards == 0 then return end
	self:sortByKeepValue(canuse_cards)
	
	local cost_card = canuse_cards[1]
	--if cost_card:isKindOf("Peach") or cost_card:isKindOf("Analeptic") then return end
	if (class_name == "Peach" and cost_card:isKindOf("Peach"))
	or (class_name == "Analeptic" and (cost_card:isKindOf("Peach") or cost_card:isKindOf("Analeptic")))
	or (class_name ~= "Peach" and (cost_card:isKindOf("Peach")
	or cost_card:isKindOf("Analeptic")
	or (cost_card:isKindOf("Jink") and self:getCardsNum("Jink") == 1)
	or (cost_card:isKindOf("Slash") and self:getCardsNum("Slash") == 1)
	or cost_card:isKindOf("Nullification")
	or cost_card:isKindOf("SavageAssault")
	or cost_card:isKindOf("ArcheryAttack")
	or cost_card:isKindOf("Duel")
	or cost_card:isKindOf("ExNihilo")))
	then
		return
	end
	
	local suit = cost_card:getSuitString()
	local number = cost_card:getNumberString()
	local card_id = cost_card:getEffectiveId()
	if player:hasSkill("quanneng_xiaonai") --[[and player:getMark("quanneng_xiaonai"..name) == 0]] then
		return (name..":quanneng_xiaonai[%s:%s]=%d"):format(suit, number, card_id)
	end
end




--嘲讽
sgs.ai_chaofeng.pangxienayou_cishanjia = 1

--------------------------------------------------
--蟹行
--------------------------------------------------

sgs.ai_skill_cardask["@xiexing_card"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local card = cards[1] or self.player:getRandomHandCard()
	return "$"..card:getEffectiveId()
end

--------------------------------------------------
--筹赈
--------------------------------------------------

sgs.ai_skill_invoke.chouzhen = function(self, data)
	if data:toString() == "draw:" then
		return self:canDraw() and (not self:willSkipPlayPhase() or self:isWeak(self.player, true))
	elseif string.startsWith(data:toString(), "get:") then
		return true
	end
	return false
end

sgs.ai_need_damaged.chouzhen = function(self, attacker, player)
	if player:getChangeSkillState("chouzhen") == 2 and attacker and self:isFriend(attacker) and not attacker:isNude() and (not self:isWeak(player) or self:getAllPeachNum(player) > 0) then
		return true
	end
	return false
end




--嘲讽
sgs.ai_chaofeng.lige_jiuyixinsheng = 2

--------------------------------------------------
--离鸢
--------------------------------------------------

sgs.ai_skill_invoke.liyuan = function(self, data)
	if data:toString() == "inc:" then
		return self:isWeak(self.player, true)
	elseif string.startsWith(data:toString(), "dec:") then
		return self.player:getMark("liyuan_inc") - self.player:getMark("liyuan_dec") > -1 and not self:isWeak(self.player, true)
	end
	return false
end

--------------------------------------------------
--不倦
--------------------------------------------------

local bujuan_skill={}
bujuan_skill.name="bujuan"
table.insert(sgs.ai_skills,bujuan_skill)
bujuan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#bujuan") < 1 and not self.player:isKongcheng() then
		return sgs.Card_Parse("#bujuan:.:")
	end
end
sgs.ai_skill_use_func["#bujuan"] = function(card, use, self)
	local cards = {}
	for _,card in sgs.qlist(self.player:getCards("h")) do
		--if card:isBlack() then
			table.insert(cards, card)
		--end
	end
	if #cards == 0 then return end
	
	local min_cost = 999
	local target
	for _, to in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local cost = self.player:distanceTo(to)
		if cost <= #cards then
			local base_value = cost * 10	--最低收益门槛，其中1牌价值为10
			if #self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, {to}, false, base_value, true) > 0 and cost < min_cost then
				min_cost = cost
				target = to
			end
		end
	end
	if target then
		local ids = dimeng_discard(self, min_cost, cards)
		if #ids > 0 then
			if use.to then
				use.to:append(target)
			end
			card_str = "#bujuan:"..table.concat(ids, "+")..":->"..target:objectName()
			use.card = sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_priority["bujuan"] = 8

--[[sgs.ai_card_intention.bujuan = function(self, card, from, tos)
    local to = tos[1]
    local intention = 10
    if self:needToLoseHp(to) or to:hasSkills(sgs.lose_hp_skills) then
        intention = -10
    end
    sgs.updateIntention(from, to, intention)
end]]





--嘲讽
sgs.ai_chaofeng.baishenguigui_xuanwuzhonggong = 0

--------------------------------------------------
--重工
--------------------------------------------------

sgs.ai_skill_askforyiji["zhonggong"] = sgs.ai_skill_askforyiji["sanli"]




--嘲讽
sgs.ai_chaofeng.qiuwu_chiwuliuhuo = 0

--------------------------------------------------
--炽翎
--------------------------------------------------

local chiling_skill={}
chiling_skill.name="chiling"
table.insert(sgs.ai_skills,chiling_skill)
chiling_skill.getTurnUseCard=function(self)
	if self.player:getMark("chiling_used") > 0 then return end
	
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards) do
		if acard:isRed() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.FireAttack or self:getOverflow() > 0) then
			if acard:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then
				local keep
				local dummy_use = { isDummy = true , to = sgs.SPlayerList() }
				self:useBasicCard(acard, dummy_use)
				if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if p:getHp() <= 1 then keep = true break end
					end
					if dummy_use.to:length() > 1 then keep = true end
				end
				if keep then sgs.ai_use_priority.Slash = sgs.ai_use_priority.FireAttack + 0.1
				else
					sgs.ai_use_priority.Slash = 2.6
					card = acard
					break
				end
			else
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("fire_attack:chiling[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end

sgs.ai_cardneed.chiling = function(to, card, self)
	return to:getHandcardNum() >= 2 and card:isRed()
end

sgs.ai_skill_cardask["@chiling_card"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local use = data:toCardUse()
	local to = use.to:first()
	if to then
		local handcards = to:getHandcards()
		local can_see = self.player:canSeeHandcard(to)
		for _,cd in ipairs(cards) do
			for _, c in sgs.qlist(handcards) do
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), to:objectName())
				if can_see or c:hasFlag("visible") or c:hasFlag(flag) then
					if c:getSuit() == cd:getSuit() then
						return "$" .. cd:getEffectiveId()
					end
				end
			end
		end
	end
	local priority = { heart = 4, spade = 3, club = 2, diamond = 1 }
	local index = -1
	local result
	for _, card in ipairs(cards) do
		if priority[card:getSuitString()] > index then
			result = card
			index = priority[card:getSuitString()]
		end
	end

	return "$" .. result:getEffectiveId()
end




--嘲讽
sgs.ai_chaofeng.lanyou_jishicanglong = 2

--------------------------------------------------
--调和
--------------------------------------------------

local tiaohe_skill = {}
tiaohe_skill.name = "tiaohe"
table.insert(sgs.ai_skills, tiaohe_skill)
tiaohe_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#tiaohe") >= 1 and not self.player:isKongcheng() then return end
	return sgs.Card_Parse("#tiaohe:.:")
end
sgs.ai_skill_use_func["#tiaohe"] = function(card, use, self)
	local cards = {}
	local suits = {}
	for _,card in sgs.qlist(self.player:getCards("h")) do
		table.insert(cards, card)
		local suit_str = card:getSuitString()
		if not table.contains(suits, suit_str) then
			table.insert(suits, suit_str)
		end
	end
	
	local targets = sgs.SPlayerList()
	self:sort(self.friends_noself, "defense")
	for _, vic in ipairs(self.friends_noself) do
		if not vic:isKongcheng() and vic:getHp() <= vic:getMaxHp() and SkillCanTarget(vic, self.player, "tiaohe") and self.player:canEffect(vic, "tiaohe") then
			targets:append(vic)
		end
	end
	self:sort(self.enemies, "defense")
	for _, vic in ipairs(self.enemies) do
		if not vic:isKongcheng() and vic:getHp() <= vic:getMaxHp() and SkillCanTarget(vic, self.player, "tiaohe") and self.player:canEffect(vic, "tiaohe") then
			targets:append(vic)
		end
	end
	if not targets:isEmpty() then
		local first, second, third, forth, fifth
		
		for _, to in sgs.qlist(targets) do
			if self:isEnemy(to) then
				if not second and self.player:canSeeHandcard(to) then		--手牌可见
					second = to
				elseif not third and getCardsNum("VisibleCard", to, self.player) > 0 and to:getHandcardNum() == 1 and table.contains(suits, to:getHandcards():first():getSuitString()) then	--仅有1张明牌，且有可以精拆的手牌
					third = to
				elseif not fifth then
					fifth = to
				end
			elseif self:isFriend(to) and ((to:getHp() == to:getMaxHp() and not self:needToLoseHp(to, self.player, true)) or (to:isWounded() and not self:needToLoseHp(to, self.player, false, false, true))) and (self.player:canSeeHandcard(to) or getCardsNum("VisibleCard", to, self.player) > 0) then
				if not first and self:isWeak(to) then
					first = to
				elseif not forth then
					forth = to
				end
			end
		end
		
		local target = first or second or third or forth or fifth	--or连接多个操作数时，表达式的返回值就是从左到右第一个不为假的值，若全部操作数值都为假，则表达式的返回值为最后一个操作数
		if target then
			self.tiaohe_card = nil
			
			local handcards = sgs.QList2Table(target:getHandcards())
			local can_see = self.player:canSeeHandcard(target)
			local cost_card
			if #handcards > 1 then
				if self:isFriend(target) then		--按价值全部排序，价值类别由是否为友方决定
					self:sortByUseValue(handcards, false)	--use value从低到高
				else
					self:sortByUseValue(handcards, false)	--use value从高到低
					handcards = sgs.reverse(handcards)		--反转为从高到低
				end
			end
			for _, c in ipairs(handcards) do
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
				if (can_see or c:hasFlag("visible") or c:hasFlag(flag)) and table.contains(suits, c:getSuitString()) then
					self.tiaohe_card = c
					
					local suit_cards = {}
					for _,card in sgs.qlist(self.player:getCards("h")) do
						if card:getSuit() == c:getSuit() then
							table.insert(suit_cards, card)
						end
					end
					local ids = dimeng_discard(self, 1, suit_cards)
					if #ids > 0 then
						cost_card = ids[1]
					end
					
					break
				end
			end
			
			if not cost_card and cost_card ~= -1 then
				local ids = dimeng_discard(self, 1, cards)
				if #ids > 0 then
					cost_card = ids[1]
				else
					return
				end
			end
			
			if use.to then
				use.to:append(target)
			end
			card_str = "#tiaohe:"..cost_card..":->"..target:objectName()
			use.card = sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_value["tiaohe"] = 1 --卡牌使用价值
sgs.ai_use_priority["tiaohe"] = 7.91 --卡牌使用优先级

sgs.ai_skill_invoke.tiaohe = function(self, data)
	local objname = string.sub(data:toString(), 8, -1)	--截取choice:后面的部分(即player:objectName())
	local to = findPlayerByObjName(self.room, objname)
	if to and self:isFriend(to) and ((to:getHp() == to:getMaxHp() and not self:needToLoseHp(to, self.player, true)) or (to:isWounded() and not self:needToLoseHp(to, self.player, false, false, true))) then
		return true
	end
	return false
end

sgs.ai_skill_choice.tiaohe = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local to = findPlayerByFlag(self.room, "tiaohe_target_AI")
		--默认顺序
		if to and self:isFriend(to) then
			if table.contains(items, "tiaohe_choice3") then
				return "tiaohe_choice3"
			else
				if to:getHandcardNum() >= self.player:getHandcardNum() and self:getOverflow() <= 0 then
					if table.contains(items, "tiaohe_choice2") then
						return "tiaohe_choice2"
					elseif table.contains(items, "tiaohe_choice1") then
						return "tiaohe_choice1"
					end
				else
					if table.contains(items, "tiaohe_choice1") then
						return "tiaohe_choice1"
					elseif table.contains(items, "tiaohe_choice2") then
						return "tiaohe_choice2"
					end
				end
			end
		else
			if table.contains(items, "tiaohe_choice2") then
				return "tiaohe_choice2"
			elseif table.contains(items, "tiaohe_choice3") then
				return "tiaohe_choice3"
			elseif table.contains(items, "tiaohe_choice1") then
				return "tiaohe_choice1"
			end
		end
	end
end

sgs.ai_skill_cardchosen.tiaohe = function(self, who, flags)
	if self.tiaohe_card then
		for _,cd in sgs.qlist(who:getHandcards()) do
			if self.tiaohe_card == cd and (self.player:canSeeHandcard(who) or cd:isOvert()) then
				self.tiaohe_card = nil
				return cd:getId()
			end
		end
	end
	if not who:isKongcheng() then
		return who:getRandomHandCard():getId()
	end
	return self:askForCardChosen(who, flags, "", sgs.Card_MethodNone)
end

--------------------------------------------------
--探玄
--------------------------------------------------

sgs.ai_skill_cardask["@tanxuan_show"] = function(self, data, pattern, target)
	local discard_list = {}
	for _,cd in sgs.qlist(self.player:getHandcards()) do
		if not cd:isOvert() then
			table.insert(discard_list, cd)
		end
	end
	self:sortByKeepValue(discard_list)
	return "$"..discard_list[1]:getEffectiveId()
end

--------------------------------------------------
--化鳞
--------------------------------------------------

sgs.ai_skill_askforag["hualin"] = function(self, card_ids)
	local first, second, third, forth
	local has_jink = (self:getCardsNum("Jink") > 0)
	self:sortIdsByValue(card_ids, "use", true)
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		local owner = self.room:getCardOwner(id)
		if card:isKindOf("EquipCard") then
			if owner and self:isEnemy(owner) then
				if not second then
					second = id
				end
			end
			if not third and not has_jink then
				third = id
			end
		elseif card:isKindOf("DelayedTrick") then
			if owner and self:isFriend(owner) then
				if not first then
					first = id
				end
			end
			if not forth and self:isWeak(self.player, true) and not has_jink then
				forth = id
			end
		end
	end
	return first or second or third or forth or -1
end




--嘲讽
sgs.ai_chaofeng.laichuanxuliang_shixibaimao = 2

--------------------------------------------------
--时溯
--------------------------------------------------

sgs.ai_skill_invoke.shisu = function(self, data)
	local dying = data:toDying()
	local hp = dying.who:getHp()

	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + hp < 1
end

--------------------------------------------------
--奇遇
--------------------------------------------------

sgs.ai_skill_use["@@qiyu"] = function(self, prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local ids = dimeng_discard(self, 1, cards)
	local cost_id = ids[1]
	if cost_id and cost_id ~= -1 then
		local target
		if self.player:getChangeSkillState("qiyu") <= 1 then	--给摸牌、弃牌
			local best_profit = 0
			local best_target
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				local profit = 0
				local draw_num = self:ImitateResult_DrawNCards(p, p:getVisibleSkillList(true))
				local max_cards = self:getOverflow(p, true)
				local handcardnum = (p:objectName() == self.player:objectName() and self.room:getCardPlace(cost_id) == sgs.Player_PlaceHand) and p:getHandcardNum()-1 or p:getHandcardNum()
				local dis_num = math.max((handcardnum + draw_num - max_cards), 0)
				local after_handcardnum = handcardnum + draw_num - dis_num
				profit = draw_num - dis_num
				if after_handcardnum > 0 then
					profit = profit + 0.3
				end
				if self:isWeak(p) then
					if after_handcardnum > 0 then
						profit = profit + 0.2
					elseif not self:needKongcheng(p) then
						profit = profit - 0.5
					end
				end
				if self:isFriend(p) then
					profit = profit + 0.1
				elseif self:isEnemy(p) then
					profit = -profit
				else
					profit = 0
					continue
				end
				if profit > best_profit then
					best_profit = profit
					best_target = p
				end
			end
			if best_profit > 0 then
				target = best_target
			end
		else													--给出牌、弃牌
			local first, second, third
			self:sort(self.friends, "handcard")
			self.friends = sgs.reverse(self.friends)
			for i = 1, #self.friends, 1 do
				local friend = self.friends[i]
				if not first and self:willSkipPlayPhase(friend) then
					first = friend
				end
				if not second then
					local has_play_skill = false
					for _, skill in sgs.qlist(friend:getVisibleSkillList(true)) do
						if not skill:isAttachedLordSkill() and not skill:isLordSkill() and string.startsWith(sgs.Sanguosha:translate(":"..skill:objectName()), "出牌阶段限一次") then
							has_play_skill = true
							break
						end
					end
					if has_play_skill then
						second = friend
					end
				end
				if not third and friend:getHandcardNum() > 0 then
					third = friend
				end
			end
			target = first or second or third
		end
		if target then
			return "#qiyu:"..cost_id..":->"..target:objectName()
		end
	end
	return "."
end




--嘲讽
sgs.ai_chaofeng.yongyuanjiang_xingkong = -1

--------------------------------------------------
--星陨
--------------------------------------------------

sgs.ai_skill_use["@@xingyun"] = function(self, prompt)
	local targets = {}
	local players = sgs.SPlayerList()
	for _, vic in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if vic:getHp() > self.player:getHp() and self.player:canEffect(vic, "xingyun") then
			players:append(vic)
		end
	end
	if not players:isEmpty() then
		players = sgs.QList2Table(players)
		self:sort(players, "hp")
		
		local target_table = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, players, false, 0, true)
		
		for _, to in ipairs(target_table) do
			if #targets >= self.player:getMark("xingyun_count") then
				break
			end
			--if self:isEnemy(to) and not self:needToLoseHp(to) and not to:hasSkills(sgs.lose_hp_skills) then
			--	table.insert(targets, to:objectName())
			--elseif self:isFriend(to) and (self:needToLoseHp(to) or (to:hasSkills(sgs.lose_hp_skills) and not self:isWeak(to))) then
			--	table.insert(targets, to:objectName())
			--end
			table.insert(targets, to:objectName())
		end
	end
	return "#xingyun:.:->"..table.concat(targets, "+")
end

sgs.ai_need_damaged.xingyun = function(self, attacker, player)
	if player:getChangeSkillState("qiyu") <= 1 and not self:isWeak(player) or (self:getAllPeachNum(player) > 0 and self:getOverflow() < 2) then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@xingyun_recast"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local to_discard = {}
	to_discard = dimeng_discard(self, 1, cards, 3)
	return to_discard[1] or cards[1]
end

--------------------------------------------------
--憨态
--------------------------------------------------

sgs.ai_cardneed.hantai = function(to, card, self)
	return card:isKindOf("Cangbaotu")
end



--嘲讽
sgs.ai_chaofeng.lixingyu_bingshayoulang = -1

--------------------------------------------------
--冰沙
--------------------------------------------------

sgs.ai_skill_invoke.bingsha = function(self, data)
	if self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) > 2 and not self:isWeak(self.player, true) then
		return false
	end
	local has_need_peach_friend = false
	for _, p in ipairs(self.friends) do
		if self:isWeak(p, p:objectName() == self.player:objectName()) and p:getLostHp() > 0 and not self:needToLoseHp(p, self.player, false, false, true) then
			has_need_peach_friend = true
		end
	end
	return has_need_peach_friend
end



--嘲讽
sgs.ai_chaofeng.haisang_meiguiwangzi = 1

sgs.ai_view_as.wenyu = function(card, player, card_place, class_name)
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or card_place == sgs.Player_PlaceEquip or (card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "wooden_ox") then
		if card:isKindOf("Slash") then
			if class_name == "Jink" then
				return ("jink:wenyu[%s:%s]=%d"):format("to_be_decided", 0, card_id)
			elseif class_name == "Nullification" then
				return ("nullification:wenyu[%s:%s]=%d"):format("to_be_decided", 0, card_id)
			end
		end
	end
end

sgs.ai_cardneed.wenyu = function(to, card, self)
	return card:isKindOf("Slash")
end

--------------------------------------------------
--解忧
--------------------------------------------------

sgs.ai_skill_cardask["@jieyou_ask"] = function(self, data, pattern, target)
	local target = data:toPlayer()
	if not target then return "." end
	if not sgs.hujiasource then sgs.hujiasource = target end
	if not sgs.hujiasource then return "." end
	if not self:isFriend(sgs.hujiasource) then return "." end
	if self:needToLoseHp(sgs.hujiasource) then return "." end
	--if self:needBear() then return "." end
	--[[local bgm_zhangfei = self.room:findPlayerBySkillName("dahe")
	if bgm_zhangfei and bgm_zhangfei:isAlive() and sgs.hujiasource:hasFlag("dahe") then
		for _, card in ipairs(self:getCards("Jink")) do
			if card:getSuit() == sgs.Card_Heart then
				return card:toString()
			end
		end
		return "."
	end]]
	return self:getCardId("Jink") or "."
end

sgs.ai_choicemade_filter.cardResponded["@jieyou_ask"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "_nil_" then
		sgs.updateIntention(player, sgs.hujiasource, -10)
		sgs.hujiasource = nil
	end
end




--嘲讽
sgs.ai_chaofeng.otome_oto_if = 3

--------------------------------------------------
--龙韵（冰火歌会）
--------------------------------------------------

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

local longyun_if_skill={}
longyun_if_skill.name="longyun_if"
table.insert(sgs.ai_skills,longyun_if_skill)
longyun_if_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#longyun_if") < 1 and not self.player:isKongcheng() and (countCheer(self.player) > 3 or (countCheer(self.player) > 1 and self:isWeak(self.player, true))) then
		return sgs.Card_Parse("#longyun_if:.:")
	end
end
sgs.ai_skill_use_func["#longyun_if"] = function(card, use, self)
	local cards = {}
	for _,card in sgs.qlist(self.player:getCards("h")) do
		if not self.player:isJilei(card) then
			table.insert(cards, card)
		end
	end
	if #cards > 0 then
		local ids = dimeng_discard(self, 1, cards)
		if #ids > 0 then
			card_str = "#longyun_if:"..ids[1]..":"
			use.card = sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_priority["longyun_if"] = 8




--嘲讽
sgs.ai_chaofeng.xinghe_yejinhuiyin = 0

--------------------------------------------------
--恒心
--------------------------------------------------

sgs.ai_skill_cardask["@hengxin_put"] = function(self, data, pattern, target)
	local damage = data:toDamage()
	if damage.from and ((self:isFriend(damage.from) and not self:needKongcheng(damage.from)) or (self:isEnemy(damage.from) and self:needKongcheng(damage.from))) then
		return "."
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local card = cards[1]
	if self:needKongcheng(self.player) and self.player:getHandcardNum() == 1 then
		local handcard = sgs.QList2Table(self.player:getCards("h"))[1]
		if not (handcard:isKindOf("Peach") or handcard:isKindOf("Analeptic") or handcard:isKindOf("Jink") or handcard:isKindOf("Nullification")) then
			card = handcard
		end
	end
	if card:isKindOf("Peach") or card:isKindOf("Analeptic") or card:isKindOf("Jink") or card:isKindOf("Nullification") then
		return "."
	end
	return card
end

sgs.ai_skill_cardask["@hengxin_put_force"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local to_discard = {}
	to_discard = dimeng_discard(self, 1, cards, 3)
	return to_discard[1] or cards[1]
end




--嘲讽
sgs.ai_chaofeng.katya_if = 1

--------------------------------------------------
--冲鸭
--------------------------------------------------

sgs.ai_skill_invoke.chongya = function(self, data)
	local target = data:toPlayer()
	if (self:isFriend(target) and self:needKongcheng(target)) or (not self:isFriend(target) and not self:needKongcheng(target)) then
		return true
	end
	return false
end

sgs.ai_cardneed.chongya = function(to, card, self)
	return card:isKindOf("Slash")
end



--嘲讽
sgs.ai_chaofeng.weiyinmao_bujuzhimao = 1

--------------------------------------------------
--炼金
--------------------------------------------------

sgs.ai_skill_discard.lianjin = function(self, discard_num, min_num, optional, include_equip)
	local toDis = {}
	local toDisOne = {}
	local types = {}
	local has_basic = false
	local hcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(hcards)
	for _, hcard in ipairs(hcards) do
		if #toDisOne == 0 and self:getUseValue(hcard) < 6 then
			table.insert(toDisOne, hcard:getId())
		end
		if not table.contains(types, hcard:getTypeId()) and not table.contains(toDis, hcard:getId()) then
			table.insert(toDis, hcard:getId())
			table.insert(types, hcard:getTypeId())
			if hcard:isKindOf("BasicCard") then
				has_basic = true
			end
		end
	end
	if self:getOverflow() >= -1 or self.player:getHandcardNum() >= 3 then	--仅在不溢出且手牌数少于2张的情况下尝试1牌炼金
		toDisOne = {}
	end
	if #toDis == 1 or (#toDis == 2 and not has_basic) then	--1牌炼金的情况
		return toDisOne
	end
	if #toDis == 2 and ((self:getOverflow() > 1 and self.player:getHp() <= 3) or self.player:getHandcardNum() > 6) then	--不2牌炼金的情况
		return {}
	end
	return toDis
end



--嘲讽
sgs.ai_chaofeng.shuiliumuyue_benzhaimonv = 1

--------------------------------------------------
--棋圣
--------------------------------------------------

local qisheng_skill = {}
qisheng_skill.name = "qisheng"
table.insert(sgs.ai_skills, qisheng_skill)
qisheng_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#qisheng") then
		return sgs.Card_Parse("#qisheng:.:")
	end
end

sgs.ai_skill_use_func["#qisheng"] = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp() < 3 then
		local zcards = self.player:getCards("he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
					self:useBasicCard(zcard, dummy_use)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = { isDummy = true }
					self:useTrickCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = { isDummy = true }
					self:useEquipCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
			end
		end
	end

	if #unpreferedCards == 0 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) then
					local dummy_use = { isDummy = true }
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getId()) end
			end
		end

		local num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unpreferedCards, card:getId())
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards, card:getId())
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
			table.insert(unpreferedCards, self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards, self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
		end
	end

	for index = #unpreferedCards, 1, -1 do
		if sgs.Sanguosha:getCard(unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then table.insert(use_cards, unpreferedCards[index]) end
	end

	if #use_cards > 0 then
		if self.room:getMode() == "02_1v1" and sgs.GetConfig("1v1/Rule", "Classical") ~= "Classical" then
			local use_cards_kof = { use_cards[1] }
			if #use_cards > 1 then table.insert(use_cards_kof, use_cards[2]) end
			use.card = sgs.Card_Parse("#qisheng:" .. table.concat(use_cards_kof, "+") .. ":")
			return
		else
			use.card = sgs.Card_Parse("#qisheng:" .. table.concat(use_cards, "+") .. ":")
			return
		end
	end
end

sgs.ai_use_value["qisheng"] = 9
sgs.ai_use_priority["qisheng"] = 2.61
sgs.dynamic_value.benefit["qisheng"]= true

--------------------------------------------------
--魔法剑·魔攻
--------------------------------------------------

sgs.ai_skill_invoke.mogong_mfj = sgs.ai_skill_invoke.xianzhi

--------------------------------------------------
--魔法剑·交剑
--------------------------------------------------

sgs.ai_skill_invoke.jiaojian_mfj = sgs.ai_skill_invoke.eight_diagram





--嘲讽
sgs.ai_chaofeng.ailufu_hualingqingtuan = -1

--------------------------------------------------
--碧影
--ai太难写了，已设置为电脑不会选的角色
--------------------------------------------------

local biying_skill={}
biying_skill.name="biying"
table.insert(sgs.ai_skills, biying_skill)
biying_skill.getTurnUseCard = function(self)
	if self.player:getMark("biying_used_thunder_slash") + self.player:getMark("biying_used_savage_assault") + self.player:getMark("biying_used_iron_chain") > 0 then
		return
	end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	local vslash = nil
	local vsavage_assault = nil
	local viron_chain = nil
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Club and not vslash and self:slashIsAvailable() then
			local new_card = sgs.Sanguosha:cloneCard("thunder_slash", card:getSuit(), card:getNumber())
			new_card:addSubcard(card)
			new_card:setSkillName("qingling")
			if self.room:isProhibited(self.player, self.player, new_card) or not self:damageIsEffective(self.player, sgs.DamageStruct_Thunder, self.player, new_card) then
				vslash = card
			end
			new_card:deleteLater()
			--return sgs.Card_Parse(("thunder_slash:biying[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
		elseif card:getSuit() == sgs.Card_Spade and not vsavage_assault then
			local new_card = sgs.Sanguosha:cloneCard("savage_assault", card:getSuit(), card:getNumber())
			new_card:addSubcard(card)
			new_card:setSkillName("qingling")
			if self.room:isProhibited(self.player, self.player, new_card) or not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, self.player, new_card) then
				vsavage_assault = card
			end
			new_card:deleteLater()
			--return sgs.Card_Parse(("savage_assault:biying[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
		elseif card:getSuit() == sgs.Card_Diamond and not viron_chain then
			viron_chain = card
			--return sgs.Card_Parse(("iron_chain:biying[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
		end
	end
	if vslash then
		return sgs.Card_Parse(("thunder_slash:biying[%s:%s]=%d"):format(vslash:getSuitString(), vslash:getNumberString(), vslash:getId()))
	elseif vsavage_assault then
		return sgs.Card_Parse(("savage_assault:biying[%s:%s]=%d"):format(vsavage_assault:getSuitString(), vsavage_assault:getNumberString(), vsavage_assault:getId()))
	elseif viron_chain then
		return sgs.Card_Parse(("iron_chain:biying[%s:%s]=%d"):format(viron_chain:getSuitString(), viron_chain:getNumberString(), viron_chain:getId()))
	end
end
