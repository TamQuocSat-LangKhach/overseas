local extension = Package("overseas_derived", Package.CardPack)
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_derived/skills")

Fk:loadTranslationTable{
  ["overseas_derived"] = "国际服衍生牌",
}

local celestialCalabash = fk.CreateCard{
  name = "&celestial_calabash",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#celestial_calabash_skill",
}
extension:addCardSpec("celestial_calabash", Card.Heart, 1)
Fk:loadTranslationTable{
  ["celestial_calabash"] = "灵宝仙葫",
  [":celestial_calabash"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>："..
    "锁定技，当你造成大于1点的伤害时或一名角色死亡时，你增加1点体力上限并回复1点体力。",
}

local horsetailWhisk = fk.CreateCard{
  name = "&horsetail_whisk",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 5,
  equip_skill = "#horsetail_whisk_skill",
}
extension:addCardSpec("horsetail_whisk", Card.Heart, 1)
Fk:loadTranslationTable{
  ["horsetail_whisk"] = "太极拂尘",
  [":horsetail_whisk"] = "装备牌·武器<br /><b>攻击范围</b>：５<br /><b>武器技能</b>："..
    "当你使用的【杀】指定目标后，目标角色需弃置一张牌，否则不可响应此【杀】；若其弃置的牌与此【杀】花色相同，你获得之。",
}

local talisman = fk.CreateCard{
  name = "&talisman",
  equip_skill = "#talisman_skill",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  on_uninstall = function(self, room, player)
    Armor.onUninstall(self, room, player)
    room:setPlayerMark(player, "@$talisman", 0)
  end,
}
extension:addCardSpec("talisman", Card.Heart, 1)
Fk:loadTranslationTable{
  ["talisman"] = "冲应神符",
  [":talisman"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，①当你受到伤害后，记录造成此伤害的牌的牌名；"..
    "②当你受到伤害时，若造成此伤害的牌的牌名被记录过，此伤害-1。",
}

local moonSpear = fk.CreateCard{
  name = "&moon_spear",
  attack_range = 3,
  equip_skill = "#moon_spear_skill",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
}
extension:addCardSpec("moon_spear", Card.Diamond, 12)
Fk:loadTranslationTable{
  ["moon_spear"] = "银月枪",
  [":moon_spear"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：当你于其他角色的回合中首次失去牌后，"..
    "你可使用【杀】。",
}

local underhanding = fk.CreateCard{
  name = "&underhanding",
  skill = "underhanding_skill",
  type = Card.TypeTrick,
  multiple_targets = true,
}
Fk:loadTranslationTable{
  ["underhanding"] = "瞒天过海",
  [":underhanding"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一至两名区域内有牌的其他角色。<br />"..
    "<b>效果</b>：你依次获得目标角色区域内的一张牌，然后依次交给目标角色一张牌。<br />【瞒天过海】不计入你的手牌上限。",
}
extension:addCardSpec("underhanding", Card.Heart, 5)
extension:addCardSpec("underhanding", Card.Club, 5)
extension:addCardSpec("underhanding", Card.Spade, 5)
extension:addCardSpec("underhanding", Card.Diamond, 5)

local redistribute = fk.CreateCard{
  name = "&redistribute",
  skill = "redistribute_skill",
  type = Card.TypeTrick,
  special_skills = { "recast" },
  multiple_targets = true,
}
extension:addCardSpec("redistribute", Card.Spade, 6)
extension:addCardSpec("redistribute", Card.Club, 6)
extension:addCardSpec("redistribute", Card.Heart, 6)
extension:addCardSpec("redistribute", Card.Diamond, 6)
Fk:loadTranslationTable{
  ["redistribute"] = "调剂盐梅",
  [":redistribute"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：两名手牌数不同的角色<br />"..
    "<b>效果</b>：若所有目标角色的手牌数不均相同，为这些角色中手牌数最小的目标角色摸一张牌，不为的弃置一张手牌。"..
    "然后若所有目标角色手牌数相同，你可将以此法弃置的牌交给一名角色。",
  ["redistribute_skill"] = "调剂盐梅",
  ["redistribute_action"] = "调剂盐梅",
  ["#redistribute-give"] = "你可将因【调剂盐梅】弃置的牌交给一名角色",
  ["#redistribute_skill"] = "选择两名手牌数不同的角色，手牌数小的目标角色摸一张牌，其余的弃置一张手牌。<br />"..
    "然后若所有目标角色手牌数相同，你可将以此法弃置的牌交给一名角色",
}

local enemyAtTheGates = fk.CreateCard{
  name = "&enemy_at_the_gates",
  skill = "enemy_at_the_gates_skill",
  type = Card.TypeTrick,
}
extension:addCardSpec("enemy_at_the_gates", Card.Spade, 7)
extension:addCardSpec("enemy_at_the_gates", Card.Club, 7)
extension:addCardSpec("enemy_at_the_gates", Card.Club, 13)
Fk:loadTranslationTable{
  ["enemy_at_the_gates"] = "兵临城下", -- 根据实际结算修改描述
  [":enemy_at_the_gates"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名其他角色<br />"..
    "<b>效果</b>：你依次亮出牌堆顶四张牌，若为【杀】，你对目标使用之；若不为【杀】，将此牌置入弃牌堆。",
}

extension:loadCardSkels{
  celestialCalabash, horsetailWhisk, talisman, moonSpear, underhanding, redistribute, enemyAtTheGates
}
return extension