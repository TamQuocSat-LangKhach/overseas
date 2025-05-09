local extension = Package("overseas_ex")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_ex/skills")

Fk:loadTranslationTable{
  ["overseas_ex"] = "国际服-界",
  ["os_ex"] = "国际界",
}

General:new(extension, "os_ex__zhangfei", "shu", 4):addSkills { "os_ex__paoxiao", "os_ex__xuhe" }
Fk:loadTranslationTable{
  ["os_ex__zhangfei"] = "界张飞",
  ["#os_ex__zhangfei"] = "万夫不当",
  ["illustrator:os_ex__zhangfei"] = "巴萨小马",

  ["~os_ex__zhangfei"] = "桃园一拜，此生无憾！",
}

General:new(extension, "os_ex__sunjian", "wu", 4, 5):addSkills {
  "yinghun",
  "wulie",
  "os_ex__polu",
}
Fk:loadTranslationTable{
  ["os_ex__sunjian"] = "界孙坚",
  ["#os_ex__sunjian"] = "武烈帝",
  ["illustrator:os_ex__sunjian"] = "漫想族",

  ["$yinghun_os_ex__sunjian1"] = "义定四野，武匡海内。", -- TODO
  ["$yinghun_os_ex__sunjian2"] = "江东男儿，皆胸怀匡扶天下之志。",

  ["~os_ex__sunjian"] = "吾身虽死，忠勇须传。",
}

General:new(extension, "os_ex__menghuo", "qun", 4):addSkills {
  "huoshou",
  "ol_ex__zaiqi",
  "os_ex__qiushou",
}
Fk:loadTranslationTable{
  ["os_ex__menghuo"] = "界孟获",
  ["#os_ex__menghuo"] = "南蛮王",
  ["illustrator:os_ex__menghuo"] = "凝聚永恒",

  ["$huoshou_os_ex__menghuo1"] = "汉人，岂是我等的对手。",
  ["$huoshou_os_ex__menghuo2"] = "定叫你们有来无回！",
  ["$ol_ex__zaiqi_os_ex__menghuo1"] = "胜败乃常事，无妨！",
  ["$ol_ex__zaiqi_os_ex__menghuo2"] = "汉人奸诈，还是不服，再战！",

  ["~os_ex__menghuo"] = "我一定要赢，要赢啊……",
}

General:new(extension, "os_ex__zhurong", "qun", 4, 4, General.Female):addSkills {
  "juxiang",
  "os_ex__lieren",
}

Fk:loadTranslationTable{
  ["os_ex__zhurong"] = "界祝融",
  ["#os_ex__zhurong"] = "野性的女王",
  ["illustrator:os_ex__zhurong"] = "alien",

  ["$juxiang_os_ex__zhurong1"] = "今日，就让这群汉人长长见识。",
  ["$juxiang_os_ex__zhurong2"] = "我的大象，终于有了用武之地。",

  ["~os_ex__zhurong"] = "这群汉人使诈……",
}

General:new(extension, "os_ex__fazheng", "shu", 3):addSkills { "os_ex__enyuan", "os_ex__xuanhuo" }
Fk:loadTranslationTable{
  ["os_ex__fazheng"] = "界法正",
  ["#os_ex__fazheng"] = "蜀汉的辅翼",
  ["illustrator:os_ex__fazheng"] = "聚一_旭",

  ["~os_ex__fazheng"] = "汉室复兴，我，是看不到了……",
}

General:new(extension, "os_ex__guohuai", "wei", 4):addSkills { "os_ex__jingce", "os_ex__yuzhang" }
Fk:loadTranslationTable{
  ["os_ex__guohuai"] = "界郭淮",
  ["#os_ex__guohuai"] = "垂问秦雍",
  ["illustrator:os_ex__guohuai"] = "凝聚永恒",

  ["~os_ex__guohuai"] = "姜维小儿，竟然……",
}

General:new(extension, "os_ex__madai", "shu", 4):addSkills { "mashu", "os_ex__qianxi" }
Fk:loadTranslationTable{
  ["os_ex__madai"] = "界马岱",
  ["#os_ex__madai"] = "临危受命",
  ["illustrator:os_ex__madai"] = "三道纹",

  ["~os_ex__madai"] = "丞相临终使命，岱已达成。",
}

General:new(extension, "os_ex__chengpu", "wu", 4):addSkills { "os_ex__lihuo", "os_ex__chunlao" }
Fk:loadTranslationTable{
  ["os_ex__chengpu"] = "界程普",
  ["#os_ex__chengpu"] = "三朝虎臣",
  ["illustrator:os_ex__chengpu"] = "monkey",

  ["~os_ex__chengpu"] = "没，没有酒了……",
}

General:new(extension, "os_ex__handang", "wu", 4):addSkills { "os_ex__gongqi", "os_ex__jiefan" }
Fk:loadTranslationTable{
  ["os_ex__handang"] = "界韩当",
  ["#os_ex__handang"] = "石城侯",
  ["illustrator:os_ex__handang"] = "monkey",

  ["~os_ex__handang"] = "今后，就靠你们了……",
}

General:new(extension, "os_ex__guyong", "wu", 3):addSkills { "os_ex__shenxing", "os_ex__bingyi" }
Fk:loadTranslationTable{
  ["os_ex__guyong"] = "界顾雍",
  ["#os_ex__guyong"] = "庙堂的玉磬",
  ["illustrator:os_ex__guyong"] = "三道纹",

  ["~os_ex__guyong"] = "陛下厚爱，雍……",
}

General:new(extension, "os_ex__caoxiu", "wei", 4):addSkills { "os_ex__qianju", "os_ex__qingxi" }
Fk:loadTranslationTable{
  ["os_ex__caoxiu"] = "界曹休",
  ["#os_ex__caoxiu"] = "龙光骐骥",
  ["illustrator:os_ex__caoxiu"] = "匠人绘",

  ["~os_ex__caoxiu"] = "此战大败，休甚是羞惭啊……",
}

return extension
