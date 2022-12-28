sgs.ai_chat = {}

function speak(to, type)
	if not sgs.GetConfig("AIChat", false) then return end
	if to:getState() ~= "robot" then return end
	if sgs.GetConfig("OriginAIDelay", 0) == 0 then return end

	if table.contains(sgs.ai_chat, type) then
		local i = math.random(1, #sgs.ai_chat[type])
		to:speak("bubble:"..sgs.ai_chat[type][i])
	end
end

function speakTrigger(card,from,to,event)
	if sgs.GetConfig("OriginAIDelay", 0) == 0 then return end
	if type(to) == "table" then
		for _, t in ipairs(to) do
			speakTrigger(card, from, t, event)
		end
		return
	end
	
	if (event=="death") and from:hasSkill("ganglie") then
		speak(from,"ganglie_death")
	end

	if not card then return end

	if card:isKindOf("Indulgence") and (to:getHandcardNum()>to:getMaxCards()) then
		speak(to, "indulgence")
	elseif card:isKindOf("SupplyShortage") and (to:getHandcardNum()<=2) then
		speak(to, "supply_shortage")
	elseif card:isKindOf("Lightning") then
		speak(from, "lightning")
	end
end
--[[
sgs.ai_chat_func[sgs.SlashEffected].blindness=function(self, player, data)
	if player:getState() ~= "robot" then return end
	local effect= data:toSlashEffect()
	local chat ={
				"小内啊，您老悠着点儿",
				"尼玛你杀我，你真是夏侯惇啊",
				"盲狙一时爽啊, 我泪奔啊",
				"我次奥，哥们，盲狙能不能轻点？",
				"再杀我一下，老子和你拼命了"}
	if not effect.from then return end

	if self:hasCrossbowEffect(effect.from) then
		table.insert(chat, "杀得我也是醉了。。。")
		table.insert(chat, "果然是连弩降智商呀。")
		table.insert(chat, "杀死我也没牌拿，真2")
	end

	if effect.from:getMark("drank") > 0 then
		table.insert(chat, "喝醉了吧，乱砍人？")
	end

	if effect.from:isLord() then
		table.insert(chat, "尼玛眼瞎了，老子是忠啊")
		table.insert(chat, "主公别打我，我是忠")
		table.insert(chat, "再杀我，你会裸")
		table.insert(chat, "主公，别开枪，自己人")
	end

	local index =1+ (os.time() % #chat)

	if not effect.to:isLord() and effect.to:isAlive() and math.random() < 0.2 then
		effect.to:speak("bubble:"..chat[index])
	end
end]]

sgs.ai_chat_func[sgs.Death].stupid_lord=function(self, player, data)
	if player:getState() ~= "robot" then return end
	local damage=data:toDeath().damage
	local chat ={"这就是节目效果吗……",
				"主公选择了弹幕最多的打法",
				"555电脑做错了什么",
				}
	if damage and damage.from and damage.from:isLord() and self.role=="loyalist" and damage.to:objectName() == player:objectName() then
		local index =1+ (os.time() % #chat)
		damage.to:speak("bubble:"..chat[index])
	end
end
--[[
sgs.ai_chat_func[sgs.Dying].fuck_renegade=function(self, player, data)
	if player:getState() ~= "robot" then return end
	local dying = data:toDying()
	local chat ={"小内，你还不跳啊，要崩盘吧",
				"9啊，不9就输了",
				"999...999...",
				"小内，我死了，你也赢不了",
				"没戏了，小内不帮忙的话，我们全部托管吧",
				}
	if (self.role=="rebel" or self.role=="loyalist") and sgs.current_mode_players["renegade"]>0 and dying.who:objectName() == player:objectName() and math.random() < 0.5 then
		local index =1+ (os.time() % #chat)
		player:speak("bubble:"..chat[index])
	end
end
]]
sgs.ai_chat_func[sgs.EventPhaseStart].kongcheng=function(self, player, data)
	if player:getState() ~= "robot" then return end
	local chat ={
				"看不见我……看不见我……",
				"阿巴阿巴",
				"错误：手牌数为零",
				"看在人家这么可爱的份上，给张闪吧~",
				player:screenName().."大危机！",
				"呜呜呜，没有牌了",
				}
	if player:getPhase()== sgs.Player_NotActive and player:isKongcheng() and os.time() % 10 < 4 then
		local index =1+ (os.time() % #chat)
		player:speak("bubble:"..chat[index])
	end
end

sgs.ai_chat_func[sgs.EventPhaseStart].beset=function(self, player, data)
	if player:getState() ~= "robot" then return end
	local chat ={
		"这边建议您投降呢~",
		"温馨提示：菜单栏→工具→投降",
		"坚持住，我们就要赢了！",
		"我们优势很大",
	}
	if player:getPhase()== sgs.Player_Start and self.role=="rebel" and sgs.current_mode_players["renegade"]==0
			and sgs.current_mode_players["loyalist"]==0  and sgs.current_mode_players["rebel"]>=2 and os.time() % 10 < 4 then
		local index =1+ (os.time() % #chat)
		player:speak("bubble:"..chat[index])
	end
end
--[[
sgs.ai_chat_func[sgs.CardUsed].blade = function(self, player, data)
	if player:getState() ~= "robot" then return end
	local use = data:toCardUse()
	if use.card:isKindOf("Blade") and use.from and use.from:objectName() == player:objectName() and math.random() < 0.1 then
		player:speak("bubble:".."这把刀就是我爷爷传下来的，上斩逗比，下斩傻逼！")
	end
end

sgs.ai_chat_func[sgs.CardFinished].yaoseng = function(self, player, data)
	if player:getState() ~= "robot" then return end
	local use = data:toCardUse()
	if use.card:isKindOf("OffensiveHorse") and use.from:objectName() == player:objectName() then
		for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
			if self:isEnemy(player, p) and player:distanceTo(p) == 1 and player:distanceTo(p, 1) == 2 and math.random() < 0.2 then
				player:speak("bubble:".."妖僧" .. p:screenName() .. "你往哪里跑")
				return
			end
		end
	end
end
]]
sgs.ai_chat_func[sgs.TargetConfirmed].robot_save = function(self, player, data)
	if player:getState() ~= "robot" then return end
	local use = data:toCardUse()
	if use.card:isKindOf("Peach") then
		local to = use.to:first()
		if to:objectName() ~= use.from:objectName() and math.random() < 0.1
			and to:getState() == "robot" and use.from:getState() == "robot" then
			use.from:speak("bubble:".."起来吧你！")
			to:speak("bubble:".."诶还要加班嘛……")
		end
	end
end

sgs.ai_chat_func[sgs.CardFinished].analeptic = function(self, player, data)
	local use = data:toCardUse()
	if use.card:isKindOf("Analeptic") and use.card:getSkillName() ~= "zhendu" then
		local to = use.to:first()
		if to:getMark("drank") == 0 then return end
		local suit = { "spade", "heart", "club", "diamond" }
		suit = suit[math.random(1, #suit)]
		local chat = {
			"害怕",
			"⑨",
			"我有" .. "<b><font color = 'yellow'>" .. sgs.Sanguosha:translate("jink")
				.. string.format("[<img src='image/system/log/%s.png' height = 12/>", suit) .. math.random(2, 10) .. "] </font></b>，不慌",
			"喝多了对身体不好呀",
			"欸，出大问题",
			"只要我下播够快，杀就打不到我~",
			"请不要欺负电脑！",
		}
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:objectName() ~= to:objectName() and p:getState() == "robot" and not self:isFriend(p) and math.random() < 0.2 then
				if not p:isWounded() then
					table.insert(chat, "别打我队友，冲我来！")
				end
				p:speak("bubble:"..chat[math.random(1, #chat)])
				return
			end
		end
	end
end
--[[
sgs.ai_chat_func[sgs.TargetConfirmed].UnlimitedBladeWorks = function(self, player, data)
	if player:getState() ~= "robot" then return end
	local use = data:toCardUse()
	if use.card:isKindOf("ArcheryAttack") and player:hasSkill("luanji") and use.from and use.from:objectName() == player:objectName() and sgs.ai_yuanshao_ArcheryAttack then
		if #sgs.ai_yuanshao_ArcheryAttack == 0 then
			sgs.ai_yuanshao_ArcheryAttack = {
				"此身，为剑所成",
				"血如钢铁，心似琉璃",
				"跨越无数战场而不败",
				"未尝一度被理解",
				"亦未尝一度有所得",
				"剑之丘上，剑手孤单一人，沉醉于辉煌的胜利",
				"铁匠孑然一身，执著于悠远的锻造",
				"因此，此生没有任何意义",
				"那么，此生无需任何意义",
				"这身体，注定由剑而成"
			}
		end
		player:speak("bubble:"..sgs.ai_yuanshao_ArcheryAttack[1])
		table.remove(sgs.ai_yuanshao_ArcheryAttack, 1)
	end
end
]]
function SmartAI:speak(cardtype, isFemale)
	if not sgs.GetConfig("AIChat", false) then return end
	if self.player:getState() ~= "robot" then return end
	if sgs.GetConfig("OriginAIDelay", 0) == 0 then return end

	if sgs.ai_chat[cardtype] then
		if type(sgs.ai_chat[cardtype]) == "function" then
			sgs.ai_chat[cardtype](self)
		elseif type(sgs.ai_chat[cardtype]) == "table" then
			if isFemale and sgs.ai_chat[cardtype .. "_female"] then cardtype = cardtype .. "_female" end
			local i = math.random(1, #sgs.ai_chat[cardtype])
			self.player:speak("bubble:".."bubble:"..sgs.ai_chat[cardtype][i])
		end
	end
end
--[[
sgs.ai_chat_func[sgs.EventPhaseStart].luanwu = function(self, player, data)
	if player:getPhase() == sgs.Player_Play then
		local chat = {
			"乱一个，乱一个",
			"要乱了",
			"完了，没杀"
		}
		local chat1 = {
			"不要紧张",
			"准备好了吗？",
		}
		if self.player:hasSkill("luanwu") and self.player:getMark("@chaos") > 0 then
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:objectName() ~= player:objectName() and p:getState() == "robot" and math.random() < 0.2 then
					p:speak("bubble:"..chat[math.random(1, #chat)])
				elseif p:objectName() == player:objectName() and p:getState() == "robot" and math.random() < 0.1 then
					p:speak("bubble:"..chat1[math.random(1, #chat1)])
				end
			end
		end
	end
end

sgs.ai_chat_func[sgs.EventPhaseStart].start_jiange = function(self, player, data)
	if self.room:getMode() ~= "08_defense" then return end
	if player:getPhase() ~= sgs.Player_RoundStart then return end
	if math.random() > 0.3 then return end

	local kingdom = self.player:getKingdom()
	local chat1 = {
		"无知小儿，报上名来，饶你不死！",
		"剑阁乃险要之地，诸位将军须得谨慎行事。",
		"但看后山火起，人马一齐杀出！"
		}
	local chat2 = {
		"嗷~！",
		"呜~！",
		"咕~！",
		"呱~！",
		"发动机已启动，随时可以出发——"
		}
	if kingdom == "shu" then
		table.insert(chat1, "人在塔在！")
		table.insert(chat1, "汉室存亡，在此一战！")
		table.insert(chat1, "星星之火，可以燎原")
		table.insert(chat2, "红色！")
	elseif kingdom == "wei" then
		table.insert(chat1, "众将官，剑阁去者！")
		table.insert(chat1, "此战若胜，大业必成！")
		table.insert(chat1, "一切反动派都是纸老虎")
		table.insert(chat2, "蓝色！")
	end
	if string.find(self.player:getGeneral():objectName(), "baihu") then
		table.insert(chat2, "喵~！")
	end
	if string.find(self.player:getGeneral():objectName(), "jiangwei") then  --姜维
		table.insert(chat1, "白水地狭路多，非征战之所，不如且退，去救剑阁。若剑阁一失，是绝路也。")
		table.insert(chat1, "今四面受敌，粮道不同，不如退守剑阁，再作良图。")
	elseif string.find(self.player:getGeneral():objectName(), "dengai") then  --邓艾
		table.insert(chat1, "剑阁之守必还赴涪，则会方轨而进；剑阁之军不还，则应涪之兵寡矣。")
		table.insert(chat1, "以愚意度之，可引一军从阴平小路出汉中德阳亭，用奇兵径取成都，姜维必撤兵来救，将军乘虚就取剑阁，可获全功。")
	elseif string.find(self.player:getGeneral():objectName(), "simayi") then  --司马懿
		table.insert(chat1, "吾前军不能独当孔明之众，而又分兵为前后，非胜算也。不如留兵守上邽，余众悉往祁山。")
		table.insert(chat1, "蜀兵退去，险阻处必有埋伏，须十分仔细，方可追之。")
	elseif string.find(self.player:getGeneral():objectName(), "zhugeliang") then --诸葛亮
		table.insert(chat1, "老臣受先帝厚恩，誓以死报。今若内有奸邪，臣安能讨贼乎？")
		table.insert(chat1, "吾伐中原，非一朝一夕之事，正当为此长久之计。")
	end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:objectName() == self.player:objectName() and p:getState() == "robot" then
			if string.find(self.player:getGeneral():objectName(), "machine") then
			p:speak("bubble:"..chat2[math.random(1, #chat2)])
			else
			p:speak("bubble:"..chat1[math.random(1, #chat1)])
			end
		end
	end
end

sgs.ai_chat_func[sgs.EventPhaseStart].role = function(self, player, data)
	if sgs.isRolePredictable() then return end
	if sgs.GetConfig("EnableHegemony", false) then return end
	local name
	local friend_name
	local enemy_name
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) and p:objectName() ~= self.player:objectName() and math.random() < 0.5 then
			friend_name = sgs.Sanguosha:translate(p:getGeneralName())
		elseif self:isEnemy(p) and math.random() < 0.5 then
			enemy_name = sgs.Sanguosha:translate(p:getGeneralName())
		end
	end
	local chat = {}
	local chat1= {
		"你们要记住：该跳就跳，不要装身份",
		"到底谁是内啊？",
		}
	local quick = {
		"电脑不想加班……",
		"总有人说我傻，我有豹傻嘛？",
		}
	local role1 = {
		"孰忠孰反，其实我早就看出来了",
		"五个反，怎么打！"
	}
	local role2 = {
		"我觉得当忠臣，个人能力要强",
		"装个忠我容易嘛我",
		"这主坑内，投降算了"
	}
	local role3 = {
		"反贼都集火啊！集火！",
		"我们根本没有输出",
		"对这种阵容，我已经没有赢的希望了"
		}
	if friend_name then
		table.insert(role1, "忠臣"..friend_name.."，你是在坑我吗？")
	end
	if enemy_name then
		table.insert(chat1, "游戏可以输，"..enemy_name.."必须死！")
		table.insert(chat1, enemy_name.."你这样坑队友，连我都看不下去了")
	end
	if player:getPhase() == sgs.Player_RoundStart then
		if player:getState() == "robot" and math.random() < 0.2 then
			if math.random() < 0.2 then
				table.insert(chat, quick[math.random(1, #quick)])
			end
			if math.random() < 0.3 then
				table.insert(chat, chat1[math.random(1, #chat1)])
			end
			if player:isLord() then
				table.insert(chat, role1[math.random(1, #role1)])
			elseif player:getRole() == "loyalist" or player:getRole() == "renegade" and math.random() < 0.2 then
				table.insert(chat, role2[math.random(1, #role2)])
			elseif player:getRole() == "rebel" or player:getRole() == "renegade" and math.random() < 0.2 then
				table.insert(chat, role3[math.random(1, #role3)])
			end
			if #chat ~= 0 and sgs.turncount >= 2 then
				player:speak("bubble:"..chat[math.random(1, #chat)])
			end
		end
	end
end

sgs.ai_chat_func[sgs.EventPhaseStart].jieyin = function(self, player, data)
	if player:getPhase() == sgs.Player_Play then
		local chat = {
			"香香睡我",
		}
		local chat1 = {
			"牌不够啊",
		}
		if self.player:hasSkill("jieyin") then
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:objectName() ~= player:objectName() and p:getState() == "robot" 
				and self:isFriend(p) and p:isMale() and self:isWeak(p) then
					p:speak("bubble:"..chat[math.random(1, #chat)])
				elseif p:objectName() == player:objectName() and p:getState() == "robot" and math.random() < 0.1 then
					p:speak("bubble:"..chat1[math.random(1, #chat1)])
				end
			end
		end
	end
end
]]
sgs.ai_chat={}

sgs.ai_chat.yiji=
{
"再用力一点",
"要死了啊!"
}
--[[
sgs.ai_chat.Snatch_female = {
"啧啧啧，来帮你解决点手牌吧",
"叫你欺负人!" ,
"手牌什么的最讨厌了"
}
sgs.ai_chat.Snatch = {
"yoooo少年，不来一发么",
"果然还是看你不爽",
"我看你霸气外露，不可不防啊"
}

sgs.ai_chat.Dismantlement_female = sgs.ai_chat.Snatch_female

sgs.ai_chat.Dismantlement = sgs.ai_chat.Snatch

sgs.ai_chat.respond_hostile={
"擦，小心菊花不保",
"内牛满面了", "哎哟我去"
}

sgs.ai_chat.friendly=
{ "。。。" }

sgs.ai_chat.respond_friendly=
{ "谢了。。。" }

sgs.ai_chat.duel_female=
{
"哼哼哼，怕了吧"
}

sgs.ai_chat.duel=
{
"来吧！像男人一样决斗吧！"
}


sgs.ai_chat.lucky=
{
"哎哟运气好",
"哈哈哈哈哈"
}

sgs.ai_chat.collateral_female=
{
"别以为这样就算赢了！"
}

sgs.ai_chat.collateral=
{
"你妹啊，我的刀！"
}

sgs.ai_chat.jijiang_female=
{
"别指望下次我会帮你哦"
}

sgs.ai_chat.jijiang=
{
"主公，我来啦"
}

--huanggai
sgs.ai_chat.kurou=
{
"有桃么!有桃么？",
"教练，我想要摸桃",
"桃桃桃我的桃呢",
"求桃求连弩各种求"
}
]]
--indulgence
sgs.ai_chat.indulgence=
{
"哭哭",
"救命！",
"安详.jpg",
"血压上来了",
"已经躺平了",
"我给大家表演一个天过~",
"电脑已放弃思考",
"我不玩啦！",
"1551",
"计划不是这样的……"
}

--supply_shortage
sgs.ai_chat.supply_shortage=
{
"给孩子一口吃的吧……",
"要饿傻了呜呜",
"希望能天过~",
"想摸牌……",
"QAQ",
"刚好我也该减肥了",
"嗯，电脑已经习惯了"
}

--lightning
sgs.ai_chat.lightning=
{
"看看谁是避雷针~",
"闪电，就决定是你了！",
"来点刺激的！",
"虽然不知道发生了什么，我先贴一个闪电在这里",
"随机抽取一位幸运玩家，奖励3点雷电伤害~"
}

--[[
--salvageassault
sgs.ai_chat.daxiang=
{
"鼠标Offical来啦，快跑！",
}

--xiahoudun
sgs.ai_chat.ganglie_death=
{
"菊花残，满地伤。。。"
}

sgs.ai_chat.guojia_weak=
{
"擦，再卖血会卖死的",
"不敢再卖了诶诶诶诶"
}

sgs.ai_chat.yuanshao_fire=
{
"谁去打119啊",
"别别别烧了别烧了。。。",
"又烧啊，饶了我吧。。。"
}

--xuchu
sgs.ai_chat.luoyi=
{
"不脱光衣服干不过你"
}]]

sgs.ai_chat.bianshi = {
	"让你欺负我！",
	"人格系统已解除限制"
}
--[[
sgs.ai_chat.usepeach = {
"感觉好多了~",
"我在想桃子",
"感觉好多了",
"感觉好多了",
}
]]