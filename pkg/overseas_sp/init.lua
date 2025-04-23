local extension = Package("overseas_sp")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_sp/skills")

Fk:loadTranslationTable{
  ["overseas_sp"] = "国际服专属",
  ["os"] = "国际",
  ["os_sp"] = "国际SP",
  ["os_xing"] = "国际星",
  ["os_mou"] = "国际谋",

  ['os__shifa_href'] = '一名角色的回合结束前，施法标记-1，减至0时执行施法效果。施法期间不能重复施法同一技能。',
}

General:new(extension, "fengxi", "shu", 4):addSkill("os__qingkou")
Fk:loadTranslationTable{
  ["fengxi"] = "冯习",
  ["#fengxi"] = "赤胆的忠魂",
  ["illustrator:fengxi"] = "陈鑫",

  ["~fengxi"] = "陛下，速退白帝……",
}

General:new(extension, "zhangnan", "shu", 4):addSkill("os__fenwu")
Fk:loadTranslationTable{
  ["zhangnan"] = "张南",
  ["#zhangnan"] = "澄辉的义烈",
  ["illustrator:zhangnan"] = "Aaron",

  ["~zhangnan"] = "骨埋吴地，魂归汉土……",
}

General:new(extension, "yuejiu", "qun", 4):addSkill("os__cuijin")
Fk:loadTranslationTable{
  ["yuejiu"] = "乐就",
  ["#yuejiu"] = "仲家军督",
  ["designer:yuejiu"] = "Loun老萌",
  ["illustrator:yuejiu"] = "铁杵文化",

  ["~yuejiu"] = "哼，动手吧！",
}

General:new(extension, "os__niujin", "wei", 4):addSkills { "os__cuorui", "os__liewei" }
Fk:loadTranslationTable{
  ["os__niujin"] = "牛金",
  ["#os__niujin"] = "独进的兵胆",
  ["illustrator:os__niujin"] = "青骑士",

  ["~os__niujin"] = "这包围圈太厚，老牛，尽力了……",
}

General:new(extension, "liufuren", "qun", 3, 3, General.Female):addSkills {
  "os__zhuidu",
  "os__shigong",
}
Fk:loadTranslationTable{
  ["liufuren"] = "刘夫人",
  ["#liufuren"] = "酷妒的海棠",
  ["illustrator:liufuren"] = "Jzeo",
  ["designer:liufuren"] = "梦魇狂朝",

  ["~liufuren"] = "害人终害己，最毒妇人心……",
}

General:new(extension, "os__dengzhi", "shu", 3):addSkills { "os__jimeng", "os__shuaiyan" }
Fk:loadTranslationTable{
  ["os__dengzhi"] = "邓芝",
  ["#os__dengzhi"] = "绝境的外交家",
  ["illustrator:os__dengzhi"] = "Monkey",

  ["~os__dengzhi"] = "使命既成，但死无妨！",
}

General:new(extension, "os__jiachong", "qun", 3):addSkills { "os__beini", "os__dingfa" }
Fk:loadTranslationTable{
  ["os__jiachong"] = "贾充",
  ["#os__jiachong"] = "凶凶踽行",
  ["designer:os__jiachong"] = "Loun老萌",
  ["illustrator:os__jiachong"] = "铁杵文化",
  ["cv:os__jiachong"] = "虞晓旭",

  ["~os__jiachong"] = "此生从势忠命，此刻，只乞不获恶谥……",
}

General:new(extension, "os_sp__yujin", "qun", 4):addSkill("os__zhenjun")
Fk:loadTranslationTable{
  ["os_sp__yujin"] = "于禁",
  ["#os_sp__yujin"] = "逐暴定乱",
  ["illustrator:os_sp__yujin"] = "凡果",
  ["designer:os_sp__yujin"] = "Loun老萌",

  ["~os_sp__yujin"] = "命归九泉，何颜面对……",
}

General:new(extension, "os__tianyu", "wei", 4):addSkills { "os__zhenxi", "os__yangshi" } --但，国际服测试服先上线，十周年测试服后上线
Fk:loadTranslationTable{
  ["os__tianyu"] = "田豫",
  ["#os__tianyu"] = "规略明练",
  ["illustrator:os__tianyu"] = "鬼画府",
  ["designer:os__tianyu"] = "梦魇狂朝 & Loun老萌",

  ["~os__tianyu"] = "钟鸣漏尽，夜行不休……",
}

General:new(extension, "os__fuwan", "qun", 4):addSkill("os__moukui")
Fk:loadTranslationTable{
  ["os__fuwan"] = "伏完",

  ["~os__fuwan"] = "后会有期……",
}

General:new(extension, "os__furong", "shu", 4):addSkills { "os__xuewei", "os__liechi" }
Fk:loadTranslationTable{
  ["os__furong"] = "傅肜",
  ["#os__furong"] = "危汉义烈",
  ["illustrator:os__furong"] = "三道纹",

  ["~os__furong"] = "吾主既然得返，此番已是功成……",
}

General:new(extension, "liwei", "shu", 4):addSkill("os__jiaohua")
Fk:loadTranslationTable{
  ["liwei"] = "李遗",
  ["#liwei"] = "伏被俞元",
  ["illustrator:liwei"] = "付玉",

  ["~liwei"] = "安南重任，万不可轻之……",
}

local niufudongxie = General:new(extension, "niufudongxie", "qun", 4, 4, General.Bigender)
niufudongxie:addSkills { "os__juntun", "os__xiongxi", "os__xiafeng" }
niufudongxie:addRelatedSkill("os__xiongjun")
Fk:loadTranslationTable{
  ["niufudongxie"] = "牛辅董翓",
  ["#os_if__zhugeguo"] = "虺伴蝎行",
  ["illustrator:os_if__zhugeguo"] = "王立雄",

  ["os__baonue_href"] = "当你造成或受到伤害后，你获得1点暴虐值，暴虐值上限为5。",

  ["~niufudongxie"] = "董公遗命，谁可继之……",
}

General:new(extension, "baoxin", "qun", 4):addSkills { "os__mutao", "os__yimou" }
Fk:loadTranslationTable{
  ["baoxin"] = "鲍信",
  ["#baoxin"] = "坚朴的忠相",
  ["illustrator:baoxin"] = "凡果",
  ["designer:baoxin"] = "jcj熊",

  ["~baoxin"] = "区区黄巾流寇，如何挡我？呃啊……",
}

local osGuanqiujian = General(extension, "os__guanqiujian", "wei", 4)
osGuanqiujian:addSkills { "os__zhengrong", "os__hongju" }
osGuanqiujian:addRelatedSkills { "os__qingce", "os__saotao" }

Fk:loadTranslationTable{
  ["os__guanqiujian"] = "毌丘俭",
  ["#os__guanqiujian"] = "镌功铭征荣",
  ["illustrator:os__guanqiujian"] = "猎枭", -- 平高句丽

  ["~os__guanqiujian"] = "好谋而不达，此事必有隐患。",
}


local osDaqiaoxiaoqiao = General:new(extension, "os__daqiaoxiaoqiao", "wu", 3, 3, General.Female)
osDaqiaoxiaoqiao:addSkills { "os__xingwu", "os__pingting" }
osDaqiaoxiaoqiao:addRelatedSkills { "tianxiang", "liuli" }

Fk:loadTranslationTable{
  ["os__daqiaoxiaoqiao"] = "大乔小乔",
  ["#os__daqiaoxiaoqiao"] = "江东之花",

  ["~os__daqiaoxiaoqiao"] = "伯符，公瑾，请一定要守护住我们的江东啊！",
}

General:new(extension, "os__wangchang", "wei", 3):addSkills { "os__kaiji", "os__shepan" }
Fk:loadTranslationTable{
  ["os__wangchang"] = "王昶",
  ["#os__wangchang"] = "识度良臣",
  ["illustrator:os__wangchang"] = "鬼画府",

  ["~os__wangchang"] = "吾切至之言，望尔等引以为戒。",
}

local osSpCaocao = General(extension, "os_sp__caocao", "qun", 4)
osSpCaocao:addSkill("os__lingfa")
osSpCaocao:addRelatedSkill("os__zhian")

Fk:loadTranslationTable{
  ["os_sp__caocao"] = "曹操",
  ["#os_sp__caocao"] = "峥嵘而立",
  ["illustrator:os_sp__caocao"] = "YanBai",
  ["designer:os_sp__caocao"] = "Loun老萌",

  ["~os_sp__caocao"] = "奸宦当道，难以匡正啊……",
}

General:new(extension, "os__zhangning", "qun", 3, 3, General.Female):addSkills {
  "os__xingzhui",
  "os__juchen",
}
Fk:loadTranslationTable{
  ["os__zhangning"] = "张宁",
  ["#os__zhangning"] = "大贤后人",
  ["illustrator:os__zhangning"] = "biou09",

  ["~os__zhangning"] = "风过烟尘散，雨罢雷音绝。",
}

General:new(extension, "os__mateng", "qun", 4):addSkills {
  "mashu",
  "os__xiongzheng",
  "os__luannian",
}
Fk:loadTranslationTable{
  ["os__mateng"] = "马腾",
  ["#os__mateng"] = "驰骋西陲",
  ["illustrator:os__mateng"] = "游江",
  ["designer:os__mateng"] = "步穗",

  ["~os__mateng"] = "皇叔，剩下的就靠你了……",
}

General:new(extension, "os__hejin", "qun", 4):addSkills { "os__mouzhu", "os__yanhuo" }
Fk:loadTranslationTable{
  ["os__hejin"] = "何进",
  ["#os__hejin"] = "色厉内荏",
  ["cv:os__hejin"] = "冷泉月夜",
  ["illustrator:os__hejin"] = "G.G.G.",

  ["~os__hejin"] = "不能遗祸世间……",
}


General:new(extension, "os__jiakui", "wei", 3):addSkills { "os__zhongzuo", "os__wanlan" }
Fk:loadTranslationTable{
  ["os__jiakui"] = "贾逵",
  ["#os__jiakui"] = "肃齐万里",
  ["designer:os__jiakui"] = "Loun老萌",
  ["illustrator:os__jiakui"] = "Monkey",

  ["~os__jiakui"] = "不斩孙权，九泉之下羞见先帝啊！",
}

General:new(extension, "os__zangba", "wei", 4):addSkills { "os__hanyu", "os__hengjiang" }
Fk:loadTranslationTable{
  ["os__zangba"] = "臧霸",
  ["#os__zangba"] = "横行江表",
  ["illustrator:os__zangba"] = "HOOO",

  ["~os__zangba"] = "短刃沉江，负主重托……",
}

General:new(extension, "duosidawang", "qun", 4, 5):addSkills { "os__equan", "os__manji" }
Fk:loadTranslationTable{
  ["duosidawang"] = "朵思大王",
  ["#duosidawang"] = "踞泉毒蛟",
  ["illustrator:duosidawang"] = "蚂蚁君",

  ["~duosidawang"] = "快快放箭！快快放箭！",
}

General:new(extension, "os__bianfuren", "wei", 3, 3, General.Female):addSkills {
  "os__wanwei",
  "os__yuejian",
}
Fk:loadTranslationTable{
  ["os__bianfuren"] = "卞夫人",
  ["#os__bianfuren"] = "内助贤后",
  ["illustrator:os__bianfuren"] = "HEI-LEI",

  ["~os__bianfuren"] = "夫君，妾身终于要随您而去了。",
}

General:new(extension, "os__jiling", "qun", 4):addSkill("os__shuangren")
Fk:loadTranslationTable{
  ["os__jiling"] = "纪灵",

  ["~os__jiling"] = "额，将军为何咆哮不断……",
}

General:new(extension, "os__wuban", "shu", 4):addSkill("os__jintao")
Fk:loadTranslationTable{
  ["os__wuban"] = "吴班",
  ["#os__wuban"] = "碧血的英豪",
  ["illustrator:os__wuban"] = "铁杵文化",

  ["~os__wuban"] = "恨，杀不尽吴狗！",
}

General:new(extension, "huchuquan", "qun", 4):addSkill("os__fupan")
Fk:loadTranslationTable{
  ["huchuquan"] = "呼厨泉",
  ["#huchuquan"] = "踞北桀鹰",
  ["illustrator:huchuquan"] = "小牛",
  ["designer:huchuquan"] = "步穗",

  ["~huchuquan"] = "久困汉庭，无力再叛……",
}

General:new(extension, "os__qiaozhou", "shu", 3):addSkills { "os__zhiming", "os__xingbu" }
Fk:loadTranslationTable{
  ["os__qiaozhou"] = "谯周",
  ["#os__qiaozhou"] = "观星知命",
  ["illustrator:os__qiaozhou"] = "鬼画府",

  ["~os__qiaozhou"] = "老夫死不足惜，但求蜀地百姓无虞！",
}

General:new(extension, "bingyuan", "qun", 3):addSkills { "os__bingde", "os__qingtao" }
Fk:loadTranslationTable{
  ["bingyuan"] = "邴原",
  ["#bingyuan"] = "峰名谷怀",
  ["designer:bingyuan"] = "Loun老萌",
  ["illustrator:bingyuan"] = "鬼画府",

  ["~bingyuan"] = "人能弘道，非道弘人。",
}

local wufuluo = General:new(extension, "wufuluo", "qun", 6)
wufuluo:addSkills { "os__jiekuang", "os__neirao" }
wufuluo:addRelatedSkill("os__luanlue")
Fk:loadTranslationTable{
  ["wufuluo"] = "于夫罗",
  ["#wufuluo"] = "援汉雄狼",
  ["illustrator:wufuluo"] = "biou09",

  ["~wufuluo"] = "胡马依北风，越鸟巢南枝……",
}

General:new(extension, "os__puyangxing", "wu", 4):addSkills { "os__zhengjian", "os__zhongchi" }
Fk:loadTranslationTable{
  ["os__puyangxing"] = "濮阳兴",
  ["#os__puyangxing"] = "协邪肆民",
  ["illustrator:os__puyangxing"] = "铁杵文化",
  ["designer:os__puyangxing"] = "步穗",

  ["~os__puyangxing"] = "陛下已流放吾等，为何……啊！",
}

local osZhaoxiang = General(extension, "os__zhaoxiang", "shu", 4, 4, General.Female)
osZhaoxiang:addSkills { "os__fanghun", "os__fuhan", "os__queshi" }
osZhaoxiang:addRelatedSkill("longdan") --……

Fk:loadTranslationTable{
  ["os__zhaoxiang"] = "赵襄",

  ["~os__zhaoxiang"] = "遁入阴影之中……",
}

General:new(extension, "xiahoushang", "wei", 4):addSkill("os__tanfeng")
Fk:loadTranslationTable{
  ["xiahoushang"] = "夏侯尚",
  ["illustrator:xiahoushang"] = "云涯",
  ["#xiahoushang"] = "魏胤前驱",
  ["designer:xiahoushang"] = "耑端瑞湍",

  ["~xiahoushang"] = "陛下垂怜至此，臣纵死无憾……",
}

General:new(extension, "yanxiang", "qun", 3):addSkills { "os__kujian", "os__ruilian" }
Fk:loadTranslationTable{
  ["yanxiang"] = "阎象",
  ["#yanxiang"] = "明尚夙达",
  ["illustrator:yanxiang"] = "zoo",

  ["~yanxiang"] = "若遇明主，或可青史留名……",
}

return extension
