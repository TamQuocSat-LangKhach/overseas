local extension = Package("overseas_if")
extension.extensionName = "overseas"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["overseas_if"] = "国际服-IF篇",
  ["os_if"] = "国际幻",
}

-- local zhugeliang = General(extension, "os_if__zhugeliang", "shu", 3)

Fk:loadTranslationTable{
  ["os_if__zhugeliang"] = "幻诸葛亮",
}

local zhaoyun = General(extension, "os_if__zhaoyun", "shu", 4)

local os__jiezhan = fk.CreateTriggerSkill{
  name = "os__jiezhan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and player ~= target and player:inMyAttackRange(target)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#os__jiezhan-invoke::" .. target.id)
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, self.name)
    if not (player.dead or target.dead) then
      player.room:useVirtualCard("slash", nil, target, player, self.name, false)
    end
  end
}

local os__longjin = fk.CreateTriggerSkill{
  name = "os__longjin",
  frequency = Skill.Wake,
  events = {fk.EnterDying},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function (self, event, target, player, data)
    return player.hp < 2
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:recover{num = 2 - player.hp, who = player, recoverBy = player, skillName = self.name}
    if not player.dead then
      room:setPlayerMark(player, "_os__longjin", 6)
      room:handleAddLoseSkills(player, "longdan|chongzhen", nil, false, true)
    end
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function (self, event, target, player, data)
    return player:getMark("_os__longjin") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("_os__longjin")
    room:setPlayerMark(player, "_os__longjin", mark - 1)
    if mark == 1 then
      room:handleAddLoseSkills(player, "-longdan|-chongzhen", nil, false, true)
    end
  end
}
local os__longjin_distance = fk.CreateDistanceSkill{
  name = "#os__longjin_distance",
  fixed_func = function (self, from, to)
    return (from:getMark("_os__longjin") > 0 and to ~= from) and 1 or nil
  end
}
os__longjin:addRelatedSkill(os__longjin_distance)

zhaoyun:addSkill(os__jiezhan)
zhaoyun:addSkill(os__longjin)
zhaoyun:addRelatedSkill("longdan")
zhaoyun:addRelatedSkill("chongzhen")

Fk:loadTranslationTable{
  ["os_if__zhaoyun"] = "幻赵云",
  ["os__jiezhan"] = "竭战",
  [":os__jiezhan"] = "其他角色的出牌阶段开始时，若其在你攻击范围内，你可摸一张牌，然后其视为对你使用一张无距离限制且计入次数限制的【杀】。",
  ["os__longjin"] = "龙烬",
  [":os__longjin"] = "觉醒技，当你进入濒死状态时，你将体力回复至2点，然后于此回合与之后的五个回合内，你视为拥有〖龙胆〗和〖冲阵〗，且你至其他角色的距离视为1。",

  ["#os__jiezhan-invoke"] = "你可发动〖竭战〗，摸一张牌，然后%dest视为对你使用一张无距离限制且计入次数限制的【杀】",

  ["$os__jiezhan1"] = "血尽鳞碎，不改匡汉之志！",
  ["$os__jiezhan2"] = "龙胆虎威，百险千难誓相随！",
  ["$os__longjin1"] = "龙烬沙场，以全大汉荣光！",
  ["$os__longjin2"] = "长坂龙魂犹在，咆哮万里长安！",
  ["$longdan_os_if__zhaoyun1"] = "进退有度，百战无伤！",
  ["$longdan_os_if__zhaoyun2"] = "龙魂缠身，虎威犹在！",
  ["$chongzhen_os_if__zhaoyun1"] = "众将士，且随老夫再战一场！",
  ["$chongzhen_os_if__zhaoyun2"] = "出入千军万马，经年横战八方！",
  ["~os_if__zhaoyun"] = "转战一生，终得见兴汉之日。",
}

local zhanghe = General(extension, "os_if__zhanghe", "wei", 4)

local os__kuiduan = fk.CreateTriggerSkill{
  name = "os__kuiduan",
  frequency = Skill.Compulsory,
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function (self, event, target, player, data)
    if not (player:hasSkill(self) and player == target and player:getHandcardNum() > 0 and data.card.trueName == "slash" and #TargetGroup:getRealTargets(data.tos) > 0) then return end
    local to = player.room:getPlayerById(data.to)
    return U.isOnlyTarget(to, data, event) and to:getHandcardNum() > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    for _, p in ipairs{player, to} do
      local cards = table.filter(p:getCardIds("h"), function (id) return Fk:getCardById(id):getMark("@@os__kuiduan_rout-inhand") == 0 end)
      if #cards > 0 then
        room:addCardMark(Fk:getCardById(table.random(cards)), "@@os__kuiduan_rout-inhand")
      end
    end
  end
}

---@param player ServerPlayer
local function getRoutNum(player)
  return #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@os__kuiduan_rout-inhand") > 0 end)
end

local os__kuiduan_dmg = fk.CreateTriggerSkill{
  name = "#os__kuiduan_dmg",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if target ~= player or data.card == nil or data.chain then return false end
    local c_event = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect, false)
    if c_event == nil then return false end
    local use_data = c_event.data[1]
    return (use_data.extra_data or {}).os__kuiduan and data.card == use_data.card and player.id == use_data.from and getRoutNum(player) > getRoutNum(data.to)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:notifySkillInvoked(player, "os__kuiduan")
    data.damage = data.damage + 1
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if player ~= target then return end
    local cards = Card:getIdList(data.card)
    return #cards == 1 and Fk:getCardById(cards[1]):getMark("@@os__kuiduan_rout-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.os__kuiduan = true
  end,
}

local os__kuiduan_slash = fk.CreateFilterSkill{
  name = "#os__kuiduan_slash",
  card_filter = function(self, card, player)
    return card:getMark("@@os__kuiduan_rout-inhand") > 0
  end,
  view_as = function(self, card)
    return Fk:cloneCard('slash', card.suit, card.number)
  end,
}

zhanghe:addSkill(os__kuiduan)
os__kuiduan:addRelatedSkill(os__kuiduan_dmg)
os__kuiduan:addRelatedSkill(os__kuiduan_slash)

Fk:loadTranslationTable{
  ["os_if__zhanghe"] = "幻张郃",
  ["os__kuiduan"] = "溃端",
  [":os__kuiduan"] = "锁定技，当你使用【杀】指定唯一目标后，你与其各将随机一张手牌标记为“溃端”牌（只能当【杀】使用或打出）。当“溃端”牌造成伤害时，若伤害来源拥有的“溃端”牌数大于受到伤害的角色，则此伤害+1。<font color='grey'>“溃端”牌暂实现为锁定视为技</font>",

  ["@@os__kuiduan_rout-inhand"] = "溃端",
  ["#os__kuiduan_dmg"] = "溃端",
  ["#os__kuiduan_slash"] = "溃端",

  ["$os__kuiduan1"] = "蜀军大败，吾等岂能失此战机！",
  ["$os__kuiduan2"] = "求胜心切，竟轻中敌计。",
  ["~os_if__zhanghe"] = "老卒迟暮，恨不能再报于国……",
}

return extension
