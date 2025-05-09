local extension = Package:new("overseas_if")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_if/skills")

Fk:loadTranslationTable{
  ["overseas_if"] = "国际服-IF篇",
  ["os_if"] = "国际幻",
  ["os_if_huan"] = "入幻",
}

--定
General:new(extension, "os_if__zhugeliang", "shu", 3, 4):addSkills { "os__beiding", "os__jielv", "os__hunyou" }
Fk:loadTranslationTable{
  ["os_if__zhugeliang"] = "幻诸葛亮",
  ["#os_if__zhugeliang"] = "天意可叹",
  ["illustrator:os_if__zhugeliang"] = "黯荧岛",

  ["~os_if__zhugeliang"] = "先帝遗志未竟，吾怎可终于半途。",
  ["!os_if__zhugeliang"] = "卧龙腾于九天，炎汉之火长明。",
}

local zhugeliang = General:new(extension, "os_if_huan__zhugeliang", "shu", 3, 4)
zhugeliang.hidden = true
zhugeliang:addSkills { "os_huan__beiding", "os_huan__jielv", "os__huanji", "os__changgui" }
Fk:loadTranslationTable{
  ["os_if_huan__zhugeliang"] = "幻诸葛亮",
  ["#os_if_huan__zhugeliang"] = "天意可叹",
  ["illustrator:os_if_huan__zhugeliang"] = "黯荧岛",

  ["~os_if_huan__zhugeliang"] = "一人之愿，终难逆天命……",
  ["!os_if_huan__zhugeliang"] = "卧龙腾于九天，炎汉之火长明。",
}

local zhaoyun = General:new(extension, "os_if__zhaoyun", "shu", 4)
zhaoyun:addSkills { "os__jiezhan", "os__longjin" }
zhaoyun:addRelatedSkills { "longdan", "chongzhen" }
Fk:loadTranslationTable{
  ["os_if__zhaoyun"] = "幻赵云",
  ["#os_if__zhaoyun"] = "天武耆龙",
  ["illustrator:os_if__zhaoyun"] = "铁杵",

  ["$longdan_os_if__zhaoyun1"] = "进退有度，百战无伤！",
  ["$longdan_os_if__zhaoyun2"] = "龙魂缠身，虎威犹在！",
  ["$chongzhen_os_if__zhaoyun1"] = "众将士，且随老夫再战一场！",
  ["$chongzhen_os_if__zhaoyun2"] = "出入千军万马，经年横战八方！",
  ["~os_if__zhaoyun"] = "转战一生，终得见兴汉之日。",
}

General:new(extension, "os_if__zhanghe", "wei", 4):addSkills { "os__kuiduan" }
Fk:loadTranslationTable{
  ["os_if__zhanghe"] = "幻张郃",
  ["#os_if__zhanghe"] = "追敌入彀",
  ["illustrator:os_if__zhanghe"] = "铁杵",

  ["~os_if__zhanghe"] = "老卒迟暮，恨不能再报于国……",
}

General:new(extension, "os_if__jiangwei", "shu", 4):addSkills { "os__qinghan", "os__zhihuan" }
Fk:loadTranslationTable{
  ["os_if__jiangwei"] = "幻姜维",
  ["#os_if__jiangwei"] = "麒麟擎汉",
  ["illustrator:os_if__jiangwei"] = "刘小狼Syaoran",

  ["~os_if__jiangwei"] = "九州未定，维有负丞相遗托。",
}

General:new(extension, "os_if__zhugeguo", "shu", 3, 3, General.Female):addSkills { "os__xianyuan", "os__lingyin" }
Fk:loadTranslationTable{
  ["os_if__zhugeguo"] = "幻诸葛果",
  ["#os_if__zhugeguo"] = "悠游清汉",
  ["illustrator:os_if__zhugeguo"] = "暗金",

  ["~os_if__zhugeguo"] = "仙缘已了，魂入轮回。",
}

General:new(extension, "os_if__simayi", "wei", 3):addSkills { "os__zongquan", "os__guimou" }
Fk:loadTranslationTable{
  ["os_if__simayi"] = "幻司马懿",
  ["#os_if__simayi"] = "权谋并施",
  ["illustrator:os_if__simayi"] = "凝聚永恒",

  ["~os_if__simayi"] = "天命已定，汝竟能逆之……",
}

General:new(extension, "os_if__weiyan", "shu", 4):addSkills { "os__piankuang", "os__qiji" }
Fk:loadTranslationTable{
  ["os_if__weiyan"] = "幻魏延",
  ["#os_if__weiyan"] = "自矜功伐",
  ["illustrator:os_if__weiyan"] = "凝聚永恒",

  ["~os_if__weiyan"] = "若无粮草之急，何致有今日此败！",
}

General:new(extension, "os_if__liushan", "shu", 3):addSkills { "os__guihanh", "os__renxian", "os__yanzuok" }
Fk:loadTranslationTable{
  ["os_if__liushan"] = "幻刘禅",
  ["#os_if__liushan"] = "汉祚永延",
  --["illustrator:os_if__liushan"] = "",

  ["~os_if__liushan"] = "天下分崩离乱，再难建兴……",
}

General:new(extension, "os_if__luxun", "wu", 3):addSkills { "os__lifengh", "os__niwo" }
Fk:loadTranslationTable{
  ["os_if__luxun"] = "幻陆逊",
  ["#os_if__luxun"] = "审机而行",
  --["illustrator:os_if__luxun"] = "",

  ["~os_if__luxun"] = "但为大吴万世基业，臣死亦不改匡谏之心！",
}

--兴
General:new(extension, "os_if__caoang", "wei", 2, 3):addSkills { "os__chihui", "os__fuxi" }
Fk:loadTranslationTable{
  ["os_if__caoang"] = "幻曹昂",
  ["#os_if__caoang"] = "穿时寻冀",
  --["illustrator:os_if__caoang"] = "",

  ["$os__huangzhu_os_if__caoang1"] = "既见明日煌煌，何惧长夜漫漫。",
  ["$os__huangzhu_os_if__caoang2"] = "九天之光，终破长空！",
  ["$os__liyuan_os_if__caoang1"] = "虽九死之地，亦当搏一线生机。",
  ["$os__liyuan_os_if__caoang2"] = "吾志在天下万方，岂能困亡于此！",
  ["~os_if__caoang"] = "漫漫长夜，何时可见光明。",
  ["!os_if__caoang"] = "拂晓之光，终慰吾灵。",
}

local caoang = General:new(extension, "os_if_huan__caoang", "wei", 2, 3)
caoang.hidden = true
caoang:addSkills { "os__huangzhu", "os__liyuan", "os__jifa" }
Fk:loadTranslationTable{
  ["os_if_huan__caoang"] = "幻曹昂",
  ["#os_if_huan__caoang"] = "穿时寻冀",
  --["illustrator:os_if_huan__caoang"] = "",

  ["$os__chihui_os_if_huan__caoang1"] = "欲成王业，蜡炬成灰终无悔！",
  ["$os__chihui_os_if_huan__caoang2"] = "但为大魏社稷，又何顾此身！",
  ["~os_if_huan__caoang"] = "纵天予再造之恩，然恨吾亦未能成业。",
  ["!os_if_huan__caoang"] = "煌煌大魏，万世长明！",
}

General:new(extension, "os_if__dingfuren", "wei", 3, 3, General.Female):addSkills { "os__shiyih", "os__chunhui" }
Fk:loadTranslationTable{
  ["os_if__dingfuren"] = "幻丁夫人",
  ["#os_if__dingfuren"] = "懿德广扬",
  --["illustrator:os_if__dingfuren"] = "",

  ["~os_if__dingfuren"] = "今生之缘未断，还盼来生……",
}

General:new(extension, "os_if__huanggai", "wu", 4):addSkills { "os__fenxian", "os__juyan" }
Fk:loadTranslationTable{
  ["os_if__huanggai"] = "幻黄盖",
  ["#os_if__huanggai"] = "休戚归烬",
  --["illustrator:os_if__huanggai"] = "",

  ["~os_if__huanggai"] = "功败……垂成……",
}

--General:new(extension, "os_if__caopi", "wei", 3):addSkills { "os__qianxiong", "os__zhengshi", "os__junsi" }
Fk:loadTranslationTable{
  ["os_if__caopi"] = "幻曹丕",
  ["#os_if__caopi"] = "溺于宸渊",
  --["illustrator:os_if__caopi"] = "",

  ["~os_if__caopi"] = "天授吾以大任，何故复而夺之……",

  ["os__qianxiong"] = "潜凶",
  [":os__qianxiong"] = "出牌阶段限一次，你可以观看牌堆顶五张牌，将其中一张牌扣置于一名角色的武将牌上。有“潜凶”牌的角色出牌阶段开始时，"..
  "你选择一项：1.本回合当其使用或打出与“潜凶”牌相同牌名的牌时，你对其造成1点伤害，本回合结束时移去其本回合使用或打出过的相同牌名的“潜凶”牌；"..
  "2.你依次使用其所有“潜凶”牌。",

  ["$os__qianxiong1"] = "暗伏甲士，待机而行！",
  ["$os__qianxiong2"] = "明既不能取胜，不妨以暗箭诛之！",

  ["os__zhengshi"] = "争適",
  [":os__zhengshi"] = "游戏开始时，令你和两名其他角色获得〖雋嗣〗。拥有〖雋嗣〗的角色死亡后或首轮开始时，若你拥有〖雋嗣〗，你可以令一名"..
  "角色因〖雋嗣〗摸牌数或弃牌数+1或-1。",
  ["$os__zhengshi1"] = "世子之位，非我莫属！",
  ["$os__zhengshi2"] = "身陷王侯之门，自然有此一遭！",
  ["$os__zhengshi3"] = "哈哈哈哈，一步之遥，可成吾业！",

  ["os__junsi"] = "雋嗣",
  [":os__junsi"] = "锁定技，每回合各限两次，当你对拥有〖雋嗣〗的角色造成伤害后，你摸一张牌；当你受到拥有〖雋嗣〗的角色造成的伤害后，"..
  "你弃置一张牌。若场上只有你拥有〖雋嗣〗，发动目标改为所有角色。",
  ["$os__junsi1"] = "鞭笞天下，方可昭吾之威德！",
  ["$os__junsi2"] = "僭越之徒，何敢妄加染指！",
  ["$os__junsi3"] = "呃啊，手足之患不除，吾心病难医！",
  ["$os__junsi4"] = "既然如此，休怪为兄无情！",
}

--General:new(extension, "os_if__dianwei", "wei", 4):addSkills { "os__miewei", "os__miyong" }
Fk:loadTranslationTable{
  ["os_if__dianwei"] = "幻典韦",
  ["#os_if__dianwei"] = "拔山超海",
  --["illustrator:os_if__dianwei"] = "",

  --["~os_if__dianwei"] = "",
  ["os__miewei"] = "灭围",
  [":os__miewei"] = "出牌阶段开始时，你可以令此阶段使用【杀】次数上限改为你攻击范围内的角色数。当你使用【杀】对目标角色造成伤害时，"..
  "此伤害+X（X为本回合被【杀】指定过的角色数，至多为5）。",
  ["os__miyong"] = "弥勇",
  [":os__miyong"] = "限定技，出牌阶段，你可以展示手牌中两张【杀】。每回合此【杀】首次使用、首次打出、首次弃置进入弃牌堆后，你获得之。",
}

local liufeng = General:new(extension, "os_if__liufeng", "shu", 4)
liufeng.shield = 1
liufeng:addSkills { "os__chenxun" }
Fk:loadTranslationTable{
  ["os_if__liufeng"] = "幻刘封",
  ["#os_if__liufeng"] = "忠烈不驯",
  --["illustrator:os_if__liufeng"] = "",

  --["~os_if__liufeng"] = "",
}

--General:new(extension, "os_if__caozhi", "wei", 3):addSkills { "os__hanhong", "os__huazhang" }
Fk:loadTranslationTable{
  ["os_if__caozhi"] = "幻曹植",
  ["#os_if__caozhi"] = "赋怀山河",
  --["illustrator:os_if__caozhi"] = "",

  --["~os_if__caozhi"] = "",
  ["os__hanhong"] = "翰鸿",
  [":os__hanhong"] = "出牌阶段每种花色限一次，你可以声明一种花色并弃置X张牌（X为你手牌中花色最多的牌数），观看牌堆顶前等量张你声明花色的牌，"..
  "获得其中一张牌。若你弃置了♣牌，你摸一张牌。",
  ["os__huazhang"] = "华章",
  [":os__huazhang"] = "出牌阶段结束时，若你的手牌数不小于2，你可以重铸所有手牌，这些牌每满足一项：花色相同、点数连续、牌名相同，"..
  "你便依次执行一项：1.摸X张牌；2.本回合手牌上限+X；3.摸X张牌且本回合手牌上限+X（X为重铸的牌数）。",
}

--General:new(extension, "os_if__caochong", "wei", 3):addSkills { "os__fushu", "os__xiumu" }
Fk:loadTranslationTable{
  ["os_if__caochong"] = "幻曹冲",
  ["#os_if__caochong"] = "枯树新芽",
  --["illustrator:os_if__caochong"] = "",

  --["~os_if__caochong"] = "",
  ["os__fushu"] = "複舒",
  [":os__fushu"] = "每回合限一次，当你需使用【桃】时，你可以与牌堆顶牌“拼点”，若你赢，视为你使用【桃】；若你没赢，你下次受到的伤害+1。",
  ["os__xiumu"] = "修睦",
  [":os__xiumu"] = "当你受到伤害后，你可以令一名其他角色选择任意张点数之和不小于13的手牌与你交换（不足则全交换）。",
}

return extension
