-- translation for God Package

return {
	["god"] = "神",

	["#shenguanyu"] = "鬼神再临",
	["shenguanyu"] = "神关羽",
	["wushen"] = "武神",
	[":wushen"] = "锁定技，你的红桃手牌视为普通【杀】。你使用红桃【杀】无距离限制。",
	["wuhun"] = "武魂",
	[":wuhun"] = "锁定技，每当你受到伤害扣减体力前，伤害来源获得等于伤害点数的“梦魇”标记。你死亡时，你选择一名存活的“梦魇”标记数最多（不为0）的角色，该角色进行判定：若结果不为【桃】或【桃园结义】，该角色死亡。",
	["@wuhun-revenge"] = "请选择“梦魇”标记最多的一名其他角色",
	["nightmare"] = "梦魇",
	["$WuhunAnimate"] = "image=image/animate/wuhun.png",
	["#WuhunRevenge"] = "%from 的“%arg2”被触发，拥有最多“梦魇”标记的角色 %to（%arg个）死亡",

	["#shenlvmeng"] = "圣光之国士",
	["shenlvmeng"] = "神吕蒙",
	["shelie"] = "涉猎",
	[":shelie"] = "摸牌阶段开始时，你可以放弃摸牌并亮出牌堆顶的五张牌：若如此做，你获得其中每种花色的牌各一张，然后将其余的牌置入弃牌堆。",
	["gongxin"] = "攻心",
	[":gongxin"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后选择其中一张红桃牌并选择一项：弃置之，或将之置于牌堆顶。",
	["gongxin:discard"] = "弃置",
	["gongxin:put"] = "置于牌堆顶",

	["#shenzhouyu"] = "赤壁的火神",
	["shenzhouyu"] = "神周瑜",
	["qinyin"] = "琴音",
	[":qinyin"] = "弃牌阶段结束时，若你于本阶段内弃置了至少两张你的牌，你可以选择一项：令所有角色各回复1点体力，或令所有角色各失去1点体力。",
	["qinyin:up"] = "所有角色回复1点体力",
	["qinyin:down"] = "所有角色失去1点体力",
	["yeyan"] = "业炎",
	[":yeyan"] = "限定技，出牌阶段，你可以对一至三名角色各造成1点火焰伤害；或你可以弃置四种花色的手牌各一张，失去3点体力并选择一至两名角色：若如此做，你对这些角色造成共计至多3点火焰伤害且对其中一名角色造成至少2点火焰伤害。",
	["greatyeyan"] = "业炎",
	["smallyeyan"] = "业炎",
	["$YeyanAnimate"] = "image=image/animate/yeyan.png",

	["#shenzhugeliang"] = "赤壁的妖术师",
	["shenzhugeliang"] = "神诸葛亮",
	["qixing"] = "七星",
	[":qixing"] = "你的起始手牌数+7。分发起始手牌后，你将其中七张扣置于武将牌旁，称为“星”。摸牌阶段结束时，你可以将至少一张手牌与等量的“星”交换。",
	["stars"] = "星",
	["@qixing-exchange"] = "请选择牌用于交换",
	["~qixing"] = "选择的牌将成为“星”",
	["kuangfeng"] = "狂风",
	[":kuangfeng"] = "结束阶段开始时，你可以将一张“星”置入弃牌堆并选择一名角色：若如此做，直到你的回合开始时，火焰伤害结算开始时，此伤害+1。",
	["@kuangfeng-card"] = "你可以发动“狂风”",
	["~kuangfeng"] = "选择一名角色→点击确定→然后在窗口中选择一张牌",
	["dawu"] = "大雾",
	[":dawu"] = "结束阶段开始时，你可以将至少一张“星”置入弃牌堆并选择等量的角色：若如此做，直到你的回合开始时，伤害结算开始时，防止这些角色受到的非雷电属性的伤害。",
	["@dawu-card"] = "你可以发动“大雾”",
	["~dawu"] = "选择若干名角色→点击确定→然后在窗口中选择相应数量的牌",
	["#QixingExchange"] = "%from 发动了“%arg2”，交换了 %arg 张手牌",
	["#FogProtect"] = "%from 的“<font color=\"yellow\"><b>大雾</b></font>”效果被触发，防止了 %arg 点伤害[%arg2]",
	["#GalePower"] = "“<font color=\"yellow\"><b>狂风</b></font>”效果被触发，%from 的火焰伤害从 %arg 点增加至 %arg2 点",

	["#shencaocao"] = "超世之英杰",
	["shencaocao"] = "神曹操",
	["guixin"] = "归心",
	[":guixin"] = "每当你受到1点伤害后，你可以依次获得所有其他角色区域内的一张牌，然后将武将牌翻面。",
	["$GuixinAnimate"] = "image=image/animate/guixin.png",
	["feiying"] = "飞影",
	[":feiying"] = "锁定技，其他角色与你的距离+1",

	["#shenlvbu"] = "修罗之道",
	["shenlvbu"] = "神吕布",
	["kuangbao"] = "狂暴",
	[":kuangbao"] = "锁定技，游戏开始时，你获得两枚“暴怒”标记。每当你造成或受到1点伤害后，你获得一枚“暴怒”标记。",
	["wrath"] = "暴怒",
	["wumou"] = "无谋",
	[":wumou"] = "锁定技，每当你使用一张非延时锦囊牌时，你须选择一项：失去1点体力，或弃一枚“暴怒”标记。",
	["wuqian"] = "无前",
	[":wuqian"] = "出牌阶段，你可以弃2枚“暴怒”标记并选择一名其他角色，本回合你获得“无双”且令该角色防具无效。",
	["shenfen"] = "神愤",
	[":shenfen"] = "出牌阶段限一次，你可以弃六枚“暴怒”标记：若如此做，所有其他角色受到1点伤害，弃置装备区的所有牌，弃置四张手牌，然后你将武将牌翻面。",
	["$ShenfenAnimate"] = "image=image/animate/shenfen.png",
	["#KuangbaoDamage"] = "%from 的“%arg2”被触发，造成 %arg 点伤害获得 %arg 枚“暴怒”标记",
	["#KuangbaoDamaged"] = "%from 的“%arg2”被触发，受到 %arg 点伤害获得 %arg 枚“暴怒”标记",
	["wumou:discard"] = "弃一枚“暴怒”标记",
	["wumou:losehp"] = "失去1点体力",

	["#shenzhaoyun"] = "神威如龙",
	["shenzhaoyun"] = "神赵云",
	["juejing"] = "绝境",
	[":juejing"] = "锁定技，摸牌阶段，你额外摸X张牌。你的手牌上限+2。（X为你已损失的体力值）",
	["longhun"] = "龙魂",
	[":longhun"] = "你可以将X张同花色的牌按以下规则使用或打出：红桃当【桃】；方块当火【杀】；黑桃当【无懈可击】；梅花当【闪】。（X为你的体力值且至少为1）",

	["#shensimayi"] = "晋国之祖",
	["shensimayi"] = "神司马懿",
	["renjie"] = "忍戒",
	[":renjie"] = "锁定技，每当你受到1点伤害后或于弃牌阶段因你的弃置而失去一张牌后，你获得一枚“忍”。",
	["bear"] = "忍",
	["baiyin"] = "拜印",
	[":baiyin"] ="觉醒技，准备阶段开始时，若你拥有四枚或更多的“忍”，你失去1点体力上限，然后获得“极略”。",
	["$BaiyinAnimate"] = "image=image/animate/baiyin.png",
	["jilve"] = "极略",
	[":jilve"] = "你可以弃一枚“忍”并发动以下技能之一：“鬼才”、“放逐”、“集智”、“制衡”、“完杀”。",
	["jilve_jizhi"] = "极略（集智）",
	["jilve_guicai"] = "极略（鬼才）",
	["jilve_fangzhu"] = "极略（放逐）",
	["lianpo"] = "连破",
	[":lianpo"] = "每当一名角色的回合结束后，若你于本回合杀死至少一名角色，你可以进行一个额外的回合。",
	["@jilve-zhiheng"] = "请发动“制衡”",
	["~zhiheng"] = "选择需要弃置的牌→点击确定",
	["#BaiyinWake"] = "%from 的“忍”为 %arg 个，触发“<font color=\"yellow\"><b>拜印</b></font>”觉醒",
	["#LianpoCanInvoke"] = "%from 在本回合内杀死了 %arg 名角色，满足“%arg2”的发动条件",
	["#LianpoRecord"] = "%from 杀死了 %to，可在 %arg 回合结束后进行一个额外的回合",
	
	["shenliubei"] = "神刘备",
	["#shenliubei"] = "誓守桃园义",
	["illustrator:shenliubei"] = "zoo",
	["longnu"] = "龙怒",
	[":longnu"] = "转换技，锁定技，出牌阶段开始时，①你失去1点体力并摸一张牌，然后本回合你的红色手牌均视为火【杀】且无距离限制；②你减1点体力上限并摸一张牌，然后本回合你的锦囊牌均视为雷【杀】且无次数限制。",
	[":longnu1"] = "转换技，锁定技，出牌阶段开始时，①你失去1点体力并摸一张牌，然后本回合你的红色手牌均视为火【杀】且无距离限制；<font color=\"#01A5AF\"><s>②你减1点体力上限并摸一张牌，然后本回合你的锦囊牌均视为雷【杀】且无次数限制。</s></font>",
	[":longnu2"] = "转换技，锁定技，出牌阶段开始时，<font color=\"#01A5AF\"><s>①你失去1点体力并摸一张牌，然后本回合你的红色手牌均视为火【杀】且无距离限制；</s></font>②你减1点体力上限并摸一张牌，然后本回合你的锦囊牌均视为雷【杀】且无次数限制。",
	["jieying"] = "结营",
	[":jieying"] = "锁定技，你始终处于横置状态；已横置的角色手牌上限+2；结束阶段开始时，你横置一名其他角色。",
	["jieying-invoke"] = "请横置一名其他角色",

	["shenluxun"] = "神陆逊",
	["#shenluxun"] = "红莲业火",
	["illustrator:shenluxun"] = "Thinking",
	["junlve"] = "军略",
	[":junlve"] = "锁定技，当你受到或造成1点伤害后，你获得一个“军略”标记。",
	["cuike"] = "摧克",
	[":cuike"] = "出牌阶段开始时，若“军略”数量为奇数，你可以对一名角色造成1点伤害；若“军略”数量为偶数，你可以横置一名角色并弃置其区域里的一张牌。若“军略”数量超过7个，你可以移去全部“军略”标记并对所有其他角色造成1点伤害。",
	["junlve-invoke"] = "你可以对一名角色造成1点伤害",
	["junlve-invoke2"] = "你可以横置一名角色并弃置其区域里的一张牌",
	["cuike:all"] = "你是否移去全部“军略”标记并对所有其他角色造成1点伤害？",
	["zhanhuo"] = "绽火",
	[":zhanhuo"] = "限定技，出牌阶段，你可以移去全部“军略”标记，令至多等量的已横置角色弃置所有装备区里的牌，然后对其中一名角色造成1点火焰伤害。",
	["zhanhuo-damage"] = "请对其中一名角色造成1点火焰伤害",

	["shenzhangliao"] = "神张辽",
	["#shenzhangliao"] = "雁门之刑天",
	["illustrator:shenzhangliao"] = "Town",
	["duorui"] = "夺锐",
	[":duorui"] = "当你于出牌阶段内对一名其他角色造成伤害后，你可以废除你的一个装备栏，然后选择该角色的武将牌上的一个技能（限定技、觉醒技、主公技除外），令其于其下回合结束前此技能无效，然后你于其下回合结束或其死亡前拥有此技能且不能发动【夺锐】。",
	["#DuoruiInvalidity"] = "%from 令 %to 的“%arg”无效",
	["duorui_area"] = "夺锐废除区域",
	["duorui_area:0"] = "废除自己的武器栏",
	["duorui_area:1"] = "废除自己的防具栏",
	["duorui_area:2"] = "废除自己的+1坐骑栏",
	["duorui_area:3"] = "废除自己的-1坐骑栏",
	["duorui_area:4"] = "废除自己的宝物栏",
	["zhiti"] = "止啼",
	[":zhiti"] = "锁定技，你攻击范围内已受伤的角色手牌上限-1；当你和这些角色拼点赢时或因【决斗】而对其造成伤害后，你恢复一个装备栏。当你受到伤害后，若伤害来源在你的攻击范围内且已受伤，你恢复一个装备栏。",
	["zhiti:0"] = "恢复自己的武器栏",
	["zhiti:1"] = "恢复自己的防具栏",
	["zhiti:2"] = "恢复自己的+1坐骑栏",
	["zhiti:3"] = "恢复自己的-1坐骑栏",
	["zhiti:4"] = "恢复自己的宝物栏",
	
	["shenganning"] = "神甘宁",
	["#shenganning"] = "江表之力牧",
	["illustrator:shenganning"] = "depp",
	["poxi"] = "魄袭",
	[":poxi"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以弃置你与其手里共计四张不同花色的牌。若如此做，根据此次弃置你的牌数量执行以下效果：没有，体力上限减1；一张，结束出牌阶段且本回合手牌上限-1；三张，回复1点体力；四张，摸四张牌。",
	["#poxi"] = "魄袭",
	["@poxi"] = "你可以弃置你与 %src 共计四张不同花色的手牌。",
	["~poxi"] = "选择四张不同花色的牌→点“确定”",
	["jieyingg"] = "劫营",
	[":jieyingg"] = "回合开始时，若全场没有“营”，你获得一个“营”。结束阶段开始时，你可以将你的“营”交给一名其他角色；有“营”的角色摸牌阶段多摸一张牌、出牌阶段可多使用一张【杀】、手牌上限+1。有“营”的其他角色回合结束时，你获得“营”和其所有手牌。",
	["jygying"] = "营",
	["@jieyingg-mark"] = "你可以将你的“营”交给一名其他角色",
	
	["ol_shenguanyu"] = "OL神关羽",
	["&ol_shenguanyu"] = "神关羽",
	["olwushen"] = "武神",
	[":olwushen"] = "锁定技，你的红桃手牌视为【杀】；你使用红桃【杀】无距离和次数限制，无法被响应。",
	["#OLwushenSlash"] = "%from 的“%arg”被触发，此【杀】不能被响应",
	
	["new_shenzhaoyun"] = "新神赵云",
	["&new_shenzhaoyun"] = "神赵云",
	["newjuejing"] = "绝境",
	[":newjuejing"] = "锁定技，你的手牌上限+2；当你进入或脱离濒死状态后，你摸一张牌。",
	["newlonghun"] = "龙魂",
	[":newlonghun"] = "你可以将至多两张同花色的牌按以下规则使用或打出：红桃当【桃】；方块当火【杀】；梅花当【闪】；黑桃当【无懈可击】。若你以此法使用了两张红色牌，则此牌回复值或伤害值+1。若你以此法使用或打出了两张黑色牌，则你弃置当前回合角色一张牌。",
	["#NewlonghunDamage"] = "%from 的“%arg”被触发，对 %to 的伤害增加为 %arg2 点",
	["#NewlonghunRecover"] = "%from 的“%arg”被触发，%to 的回复值增加为 %arg2 点",
	
	["ol_shenzhangliao"] = "OL神张辽",
	["&ol_shenzhangliao"] = "神张辽",
	["illustrator:ol_shenzhangliao"] = "Town",
	["olduorui"] = "夺锐",
	[":olduorui"] = "当你于出牌阶段内对一名其他角色造成伤害后，若其未因“夺锐”导致技能无效，你可以令该角色的武将牌上的一个技能于下回合结束前无效。若如此做，（在所有结算完成后）你结束出牌阶段。",
	["olzhiti"] = "止啼",
	[":olzhiti"] = "锁定技，你攻击范围内已受伤的角色手牌上限-1；若场上受伤角色的数量：不小于1，你的手牌上限+1；不小于3，你摸牌阶段摸牌数量+1；不小于5，你的回合结束时，可废除一名有装备栏的角色一个随机的装备栏。",
	["@olzhiti-throw"] = "你可以废除一名角色随机的一个装备栏",

	["shencaopi"] = "神曹丕",
	["#shencaopi"] = "",
	["illustrator:shencaopi"] = "鬼画府",
	["chuyuan"] = "储元",
	[":chuyuan"] = "当一名角色到伤害后，你可令其摸1张牌，然后其将一张手牌置于你的武将牌上，称为“储”；你的手牌上限+X（X为储的数量）。",
	["cychu"] = "储",
	["@chuyuan-put"] = "请将一张手牌置于 %src 武将牌上",
	["dengji"] = "登极",
	[":dengji"] = "觉醒技，准备阶段开始时，若你的“储”不少于3，你减1点体力上限，获得武将牌上的“储”，获得“奸雄”和“天行”。",
	["#DengjiWake"] = "%from 的“<font color=\"yellow\"><b>储</b></font>”的数量为 %arg，触发“%arg2”觉醒",
	["tianxing"] = "天行",
	[":tianxing"] = "觉醒技，准备阶段开始时，若你的“储”不少于3，你减1点体力上限，获得武将牌上的“储”，失去“储元”，从“界仁德”、“界制衡”、“界乱击”、“界放权”中选择一个获得。",
	
	["shenzhenji"] = "神甄姬",
	["#shenzhenji"] = "",
	["illustrator:shenzhenji"] = "鬼画府",
	["shenfu"] = "神赋",
	[":shenfu"] = "回合结束时，若你的手牌数为：奇数，你可对一名其他角色造成1点雷电伤害，若造成其死亡，你可重复此流程；偶数，你可令一名角色摸一张牌或你弃置其一张手牌，若执行后该角色的手牌数等于其体力值，你可重复此流程（不能对本回合指定过的目标使用）。",
	["@shenfu-ou"] = "你可令一名角色摸一张牌或你弃置其一张手牌",
	["@shenfu-ji"] = "你可对一名其他角色造成1点雷电伤害",
	["qixian"] = "七弦",
	[":qixian"] = "锁定技，你的手牌上限为7。",
	
	["shenlvbu3"] = "吕布-虎牢关",
	["#shenlvbu3"] = "神鬼无前",
	["illustrator:shenlvbu3"] = "LiuHeng",
	["shenqu"] = "神躯",
	[":shenqu"] = "一名角色的回合开始时，若你的手牌数不大于体力上限，你可以摸两张牌。当你受到伤害后，你可以使用一张【桃】。",
	["@shenqu-peach"] = "你可以使用一张【桃】",
	["jiwu"] = "极武",
	[":jiwu"] = "出牌阶段，你可以弃置一张手牌，然后获得以下一个技能直到回合结束：完杀，烈刃，强袭，旋风。",
}