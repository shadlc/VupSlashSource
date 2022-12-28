-- this script to store the basic configuration for game program itself
-- and it is a little different from config.ini

config = {
	big_font = 56,
	small_font = 27,
	tiny_font = 18,
	kingdoms = { "wei", "shu", "wu", "qun", "god" },
	kingdom_colors = {
		wei = "#547998",
		shu = "#D0796C",
		wu = "#4DB873",
		qun = "#8A807A",
		god = "#96943D",
			--新势力颜色
		psp = "#5B9FE5",
		novus = "#96943D",
		usthree = "#74BD54",
		facemoe = "#9C7AAC",
		--xuyanshe = "#775743",
		xuyanshe = "#88CC33",
		yueshaoshe = "#DAA520",
		niya = "#D87283",
		chaociyuan = "#FFAD43",
		yuejianchicha = "#753924",
		TheVirkyrie = "#5F89BD",
		blondel = "#249A97",
		vector = "#191970",
		keasofer = "#2F4F4F",
		individual = "#8A807A",
		bisonpro = "#D0796C",
		VirtualDove = "#97D1D4",
		ciyuanjingxiang = "#5A504A",
		team_fire = "#D0796C",
		team_ice = "#547998"
	},

	skill_type_colors = {
		compulsoryskill = "#0000FF",
		limitedskill = "#FF0000",
		wakeskill = "#800080",
		lordskill = "#FFA500",
		oppphskill = "#008000",
		--changeskill = "#FFC0CB",
		changeskill = "#CB5063",
		warmupskill = "#8B4513",
	},

	package_names = {
		"StandardCard",
		"StandardExCard",
		"Maneuvering",
		"LimitationBroken",
		"SPCard",
		"Nostalgia",
		"New3v3Card",
		"New3v3_2013Card",
		"New1v1Card",
		"YitianCard",
	--	"Joy",
		"Disaster",
		"JoyEquip",

		"Standard",
		"Wind",
		"Fire",
		"Thicket",
		"Mountain",
		"Yin",
		"Lei",
		"God",
		"YJCM",
		"YJCM2012",
		"YJCM2013",
		"YJCM2014",
		"YJCM2015",
		"YCZH2016",
		"YCZH2017",
		"JXTP",
		"OLJXTP",
		"MobileJXTP",
		"SP",
		"SP2",
		"SP3",
		"OL",
		"JSP",
		"BGM",
		"Assassins",
		"Special3v3",
		"Special3v3Ext",
		"Special1v1",
		"Special1v1Ext",
		"Doudizhu",
		"Happy2v2";
		"TaiwanSP",
		"TaiwanYJCM" ,
		"Miscellaneous",
		"BGMDIY",
		"Ling",
		"Hegemony",
		"HFormation",
		"HMomentum",
		"HegemonySP",
		"JSP",
		"NostalStandard",
		"NostalWind",
		"NostalYJCM",
		"NostalYJCM2012",
		"NostalYJCM2013",
		"JianGeDefense",
		"BossMode",
		"Yitian",
	"Wisdom",
		"Test"
	},

	--可被玩家勾选或取消的扩展包
	available_general_packages = {
		"VupV0",
		"tietiebattle",
		"zzsystem",
		"icefire",
	},

	hulao_generals = {
		"package:nostal_standard",
		"package:wind",
		"package:nostal_wind",
		"zhenji", "zhugeliang", "sunquan", "sunshangxiang",
		"-zhangjiao", "-zhoutai", "-caoren", "-yuji",
		"-nos_yuji"
	},

	xmode_generals = {
		"package:nostal_standard",
		"package:wind",
		"package:fire",
		"package:nostal_wind",
		"zhenji", "zhugeliang", "sunquan", "sunshangxiang",
		"-nos_huatuo",
		"-zhangjiao", "-zhoutai", "-caoren", "-yuji",
		"-nos_zhangjiao", "-nos_yuji"
	},

	easy_text = {
		"太慢了，做两个俯卧撑吧！",
		"快点吧，我等的花儿都谢了！",
		"高，实在是高！",
		"好手段，可真不一般啊！",
		"哦，太菜了。水平有待提高。",
		"你会不会玩啊？！",
		"嘿，一般人，我不使这招。",
		"呵，好牌就是这么打地！",
		"杀！神挡杀神！佛挡杀佛！",
		"你也忒坏了吧？！"
	},

	roles_ban = {
	},

	kof_ban = {
		"sunquan",
	},

	bossmode_ban = {
		"caopi",
		"manchong",
		"xusheng",
		"yuji",
		"caiwenji",
		"zuoci",
		"lusu",
		"bgm_diaochan",
		"shenguanyu",
		"nos_yuji",
		"nos_zhuran"
	},

	basara_ban = {
		"dongzhuo",
		"zuoci",
		"shenzhugeliang",
		"shenlvbu",
		"bgm_lvmeng",
		"zhanggongqi"
	},

	hegemony_ban = {
		"xiahoujuan"
	},

	pairs_ban = {
		"huatuo", "zuoci", "bgm_pangtong", "kof_nos_huatuo", "nos_huatuo",
		"simayi+dengai",
		"xiahoudun+luxun", "xiahoudun+zhurong", "xiahoudun+zhangchunhua", "xiahoudun+nos_luxun", "xiahoudun+nos_zhangchunhua",
		"caoren+shenlvbu", "caoren+caozhi", "caoren+bgm_diaochan", "caoren+bgm_caoren", "caoren+nos_caoren",
		"guojia+dengai",
		"zhenji+zhangjiao", "zhenji+nos_zhangjiao", "zhenji+nos_wangyi",
		"zhanghe+yuanshu",
		"dianwei+weiyan",
		"dengai+zhangjiao", "dengai+shensimayi", "dengai+zhugejin", "dengai+nos_simayi", "dengai+nos_guojia", "dengai+nos_zhangjiao",
		"zhangfei+zhangchunhua", "zhangfei+nos_huanggai", "zhangfei+nos_zhangchunhua",
		"zhugeliang+xushu", "zhugeliang+nos_xushu",
		"huangyueying+wolong", "huangyueying+ganning", "huangyueying+yuanshao", "huangyueying+yanliangwenchou", "huangyueying+nos_huanggai",
		"huangzhong+xusheng",
		"weiyan+nos_huanggai",
		"wolong+luxun", "wolong+zhangchunhua", "wolong+nos_huangyueying", "wolong+nos_luxun", "wolong+nos_zhangchunhua",
		"menghuo+dongzhuo", "menghuo+zhugedan", "menghuo+heg_dongzhuo",
		"sunquan+sunshangxiang",
		"ganning+nos_huangyueying",
		"lvmeng+yuanshu",
		"huanggai+nos_huanggai",
		"luxun+yanliangwenchou", "luxun+guanxingzhangbao", "luxun+guanping", "luxun+guyong",
			"luxun+nos_liubei", "luxun+nos_yuji", "luxun+nos_guanxingzhangbao",
		"sunshangxiang+shensimayi", "sunshangxiang+heg_luxun", "sunshangxiang+nos_huanggai",
		"sunce+guanxingzhangbao", "sunce+nos_guanxingzhangbao",
		"xiaoqiao+zhangchunhua", "xiaoqiao+nos_zhangchunhua",
		"yuanshao+nos_huangyueying", "yuanshao+nos_huanggai",
		"yanliangwenchou+zhangchunhua", "yanliangwenchou+nos_huangyueying", "yanliangwenchou+nos_huanggai", "yanliangwenchou+nos_luxun",
			"yanliangwenchou+nos_zhangchunhua",
		"dongzhuo+shenzhaoyun", "dongzhuo+wangyi", "dongzhuo+diy_wangyuanji", "dongzhuo+nos_huanggai", "dongzhuo+nos_zhangchunhua", "dongzhuo+nos_wangyi",
		"st_huaxiong+nos_huanggai",
		"shencaocao+caozhi",
		"shenlvbu+caozhi", "shenlvbu+liaohua", "shenlvbu+bgm_diaochan", "shenlvbu+bgm_caoren", "shenlvbu+nos_caoren",
		"shenzhaoyun+huaxiong", "shenzhaoyun+zhugedan", "shenzhaoyun+heg_dongzhuo",
		"caozhi+bgm_diaochan", "caozhi+bgm_caoren", "caozhi+nos_caoren",
		"gaoshun+zhangchunhua", "gaoshun+nos_zhangchunhua",
		"wuguotai+zhangchunhua", "wuguotai+caochong", "wuguotai+nos_huanggai", "wuguotai+nos_zhangchunhua", "wuguotai+nos_caochong",
		"zhangchunhua+guanxingzhangbao", "zhangchunhua+guanping", "zhangchunhua+guyong", "zhangchunhua+xiahouba", "zhangchunhua+zhugeke",
			"zhangchunhua+heg_luxun", "zhangchunhua+neo_zhangfei", "zhangchunhua+nos_liubei", "zhangchunhua+nos_zhangfei",
			"zhangchunhua+nos_yuji", "zhangchunhua+nos_guanxingzhangbao",
		"guanxingzhangbao+bgm_zhangfei", "guanxingzhangbao+heg_sunce", "guanxingzhangbao+nos_huanggai", "guanxingzhangbao+nos_luxun", "guanxingzhangbao+nos_zhangchunhua",
		"huaxiong+nos_huanggai",
		"liaohua+bgm_diaochan",
		"wangyi+zhugedan", "wangyi+heg_dongzhuo",
		"guanping+nos_luxun", "guanping+nos_zhangchunhua",
		"guyong+nos_luxun", "guyong+nos_zhangchunhua",
		"yuanshu+nos_lvmeng",
		"xiahouba+nos_huanggai", "xiahouba+nos_zhangchunhua",
		"zhugedan+diy_wangyuanji", "zhugedan+nos_zhangchunhua", "zhugedan+nos_wangyi",
		"zhugeke+nos_zhangchunhua",
		"bgm_diaochan+bgm_caoren", "bgm_diaochan+nos_caoren",
		"bgm_caoren+nos_caoren",
		"bgm_zhangfei+nos_guanxingzhangbao",
		"diy_wangyuanji+heg_dongzhuo",
		"hetaihou+nos_zhuran",
		"heg_sunce+nos_guanxingzhangbao",
		"heg_dongzhuo+nos_zhangchunhua", "heg_dongzhuo+nos_wangyi",
		"neo_zhangfei+nos_huanggai", "neo_zhangfei+nos_zhangchunhua",
		"nos_liubei+nos_luxun", "nos_liubei+nos_zhangchunhua",
		"nos_zhangfei+nos_huanggai", "nos_zhangfei+nos_zhangchunhua",
		"nos_huangyueying+nos_huanggai",
		"nos_huanggai+nos_guanxingzhangbao",
		"nos_luxun+nos_yuji", "nos_luxun+nos_guanxingzhangbao",
		"nos_yuji+nos_zhangchunhua",
		"nos_zhangchunhua+heg_luxun", "nos_zhangchunhua+nos_guanxingzhangbao",
	},

	--PVE模式
	--BOSS池：黑魔遥、无双戦神
	pve_saver_lord = "newzhan_boss|heimoyao_boss",
	--pve_saver_lord = "heimoyao_boss",
	
	--CP协战模式
	--后宫王池：雪狐、秋凛子、李豆沙、折原露露
	couple_lord = "xuehusang_zizaisuixin|qiulinzi_wangyinwunv|lidousha_xunxingzhuzhong|zheyuanlulu_guanceduixiang",
	--CP池
	couple_couples = {
		--雪狐和后宫团：夕兔、奈奈莉娅、黎歌、纱耶、纱音
		"xuehusang_zizaisuixin,xitu_duoshelingtu,nainailiya_yuanbenlinyuan,lige_jiachuantianyi,shaye_rougumeisheng,shayin_linglongyemo",
		--红秋豹
		"hongxiaoyin_heilangniao,qiulinzi_wangyinwunv,baishenyao_zhaijiahaibao",
		--星汐笙歌
		"xingxi_tianjiliuxing,shengge_wuxiugewu",
		--东秋星
		"dongaili_xingtu,qiulinzi_wangyinwunv,xingxi_tianjiliuxing",
		--两魔王+YY					--注意：本模式中带变身技的女性角色可能会造成混乱，两个魔王是男性所以没问题
		"yizhiyy_mianbaoren,ximoyou_jiweimowang,xiaheyi_yinyangshi",
		--狼YY
		"yizhiyy_mianbaoren,liantai_bingyuanlangwang",
		--东南
		"dongaili_xingtu,nanyinnai_maomaotou",
		--兔步猫
		"lingnainainai_fentujk,buding_qiaoxinmiyou,xingzhigumiya_mengmao",
		--貂月
		"chushuang_jinglingxuediao,xiyue_shenshengxuantu",
		--希贝尔尤特拉法
		"xibeier_sanjueweibian,youte_lianxinmonv,lafa_duoluotianshi",
		--希贝尔+黄绿蕾蒂
		"xibeier_sanjueweibian,leidi_cuilianzhiyuan",
		"xibeier_sanjueweibian,leidi_haizaomao",
		--花满绿蕾蒂
		"huaman_wunianhuajiang,leidi_haizaomao",
		--库姬玖麻
		"kuji_chaoyongyuge,jiuma_hanshixianggong",
		--熊崽花满
		"xiongzai_beijixingdeshouwangzhe,huaman_wunianhuajiang",
		--希桃
		"xiaoxi_chixingai,xiaotao_tauxingai",
		--柔兰
		"xiaorou_cpmode,lanyin_yuezhigongzhutu",
		--艾露露兰音
		"ailulu_hunaoxiaoxiongmao,lanyin_yuezhigongzhutu",
		--芳乃推+花火
		"beishanghuahuo_xuanlancuantianhou,fangnaitui_yinyangmeiying",
		--芳乃推+艾冰
		"aibing_yijinglingzhu,fangnaitui_yinyangmeiying",
		--芳乃推+星梦
		"xingmengzhenxue_rongyixiaohu,fangnaitui_yinyangmeiying",
		--芳乃推+秋乌
		"qiuwu_chiwuliuhuo,fangnaitui_yinyangmeiying",
		--纱耶纱音芳乃推
		"shaye_rougumeisheng,shayin_linglongyemo,fangnaitui_yinyangmeiying",
		--纱耶木木
		"shaye_rougumeisheng,pengshanmu_zhuoluofengchan",
		--纱音桐谷和纱
		"shayin_linglongyemo,tongguhesha_cpmode",
		--月兮扇宝
		"yuexi_ruoyuelongnv,shanbao_fengyaliangyou",
		--信使鹿
		"xinshiakane_huaxingzhimao,lichuanfeng_yuejianaidoulu",
		--松鼠仓鼠
		"wuqian_daweiba,bison_cpmode",
		--头发夕兔
		"toufa_shiyixian,xitu_duoshelingtu",
		--小柔梦音艾露露
		"xiaorou_cpmode,mengyinchanuo_xiuwaihuizhong,ailulu_hunaoxiaoxiongmao",
		--露蒂丝秋海月
		"qiulinzi_wangyinwunv,ludisi_guguyisheng,haiyuexun_yangyingfuguang",
		--露蒂丝北
		"qiulinzi_wangyinwunv,beiyouxiang_motaishouke",
		--季毅绫濑光
		"jiyi_changbeibuxie,linglaiguang_shengsixiangyi",
		--阿露波卡诺娅紫海由爱
		"shanjiaoalubo_liuciyuanouxiang,kanuoya_akanluerbanlong,zihaiyouai_xiguamiao",
		--芬里尔叶神奈
		"fenlier_xiaolangzai,yeshennai_xiaolangzai",
		--占戈戈和单推人
		"zhangege_v2,menglongshaozhu_bileizhen",
		--能美沙月
		"nengmeifengling_lanmeiyushi,shayue_fanqietianshi"
	},
	
	--冰火歌会模式
	--角色池：白神遥 步玎 红晓音 西魔幽 夏鹤仪 绫奈奈奈 东爱璃 星汐 笙歌 冰糖 花园serena 绮良 次元酱 木糖纯 诗小雅 小希小桃 小柔 兰音 艾露露 山椒阿露波 花满 雪狐 夏川玥玥 穆小泠 早凉 露蒂丝 海桑 乙女音 高槻律 千草はな
	if_generals = {
		"baishenyao_if",
		"buding_qiaoxinmiyou",
		"hongxiaoyin_heilangniao",
		"ximoyou_jiweimowang",
		"xiaheyi_yinyangshi",
		"lingnainainai_fentujk",
		"dongaili_xingtu",
		"xingxi_if",
		"shengge_wuxiugewu",
		"bingtang_if",
		--"jinghua_if",
		"hanazono_serena_if",
		"qiliang_shixingeyin",
		"ciyuanjiang_mengxinyindaoyuan",
		"mutangchun_recorder",
		"shixiaoya_xianyadan",
		"xiaoxixiaotao_eniac",
		"xiaorou_if",
		"lanyin_yuezhigongzhutu",
		"ailulu_hunaoxiaoxiongmao",
		"shanjiaoalubo_liuciyuanouxiang",
		"huaman_wunianhuajiang",
		"xuehusang_zizaisuixin",
		"xiachuanyueyue_if",
		"muxiaoling_shouyindexuemei",
		"zaoliang_jiqimao",
		"ludisi_guguyisheng",
		"haisang_meiguiwangzi",
		"otome_oto_if",
		"nainailiya_yuanbenlinyuan",
		"katya_if",
		"takatsuki_ritsu",
		"chigusa_hana"
	},
	
	convert_pairs = {
	
	},

	removed_hidden_generals = {
	},

	extra_hidden_generals = {
	},

	removed_default_lords = {
	},

	extra_default_lords = {
	},

	bossmode_default_boss = {
		"boss_chi+boss_mei+boss_wang+boss_liang",
		"boss_niutou+boss_mamian",
		"boss_heiwuchang+boss_baiwuchang",
		"boss_luocha+boss_yecha"
	},

	bossmode_endless_skills = {
		"bossguimei", "bossdidong", "nosenyuan", "bossshanbeng+bossbeiming+huilei+bossmingbao",
		"bossluolei", "bossguihuo", "bossbaolian", "mengjin", "bossmanjia+bazhen",
		"bossxiaoshou", "bossguiji", "fankui", "bosslianyu", "nosjuece",
		"bosstaiping+shenwei", "bosssuoming", "bossxixing", "bossqiangzheng",
		"bosszuijiu", "bossmodao", "bossqushou", "yizhong", "kuanggu",
		"bossmojian", "bossdanshu", "shenji", "wushuang", "wansha"
	},

	bossmode_exp_skills = {
		"mashu:15",
		"tannang:25",
		"yicong:25",
		"feiying:30",
		"yingyang:30",
		"zhenwei:40",
		"nosqicai:40",
		"nosyingzi:40",
		"zongshi:40",
		"qicai:45",
		"wangzun:45",
		"yingzi:50",
		"kongcheng:50",
		"nosqianxun:50",
		"weimu:50",
		"jie:50",
		"huoshou:50",
		"hongyuan:55",
		"dangxian:55",
		"xinzhan:55",
		"juxiang:55",
		"wushuang:60",
		"xunxun:60",
		"zishou:60",
		"jingce:60",
		"shengxi:60",
		"zhichi:60",
		"bazhen:60",
		"yizhong:65",
		"jieyuan:70",
		"mingshi:70",
		"tuxi:70",
		"guanxing:70",
		"juejing:75",
		"jiangchi:75",
		"bosszuijiu:80",
		"shelie:80",
		"gongxin:80",
		"fenyong:85",
		"kuanggu:85",
		"yongsi:90",
		"zhiheng:90",
	},

	jiange_defense_kingdoms = {
		loyalist = "shu",
		rebel = "wei",
	},

	jiange_defense_machine = {
		wei = "jg_machine_tuntianchiwen+jg_machine_shihuosuanni+jg_machine_fudibian+jg_machine_lieshiyazi",
		shu = "jg_machine_yunpingqinglong+jg_machine_jileibaihu+jg_machine_lingjiaxuanwu+jg_machine_chiyuzhuque",
	},

	jiange_defense_soul = {
		wei = "jg_soul_caozhen+jg_soul_simayi+jg_soul_xiahouyuan+jg_soul_zhanghe",
		shu = "jg_soul_liubei+jg_soul_zhugeliang+jg_soul_huangyueying+jg_soul_pangtong",
	}
}
