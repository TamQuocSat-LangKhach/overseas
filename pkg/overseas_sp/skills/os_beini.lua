local osBeini = fk.CreateSkill {
  name = "os__beini"
}

Fk:loadTranslationTable{
  ["os__beini"] = "悖逆",
  [":os__beini"] = "出牌阶段限一次，你可以选择一名体力值不小于你的角色，令你或其摸两张牌，然后未摸牌的角色视为对摸牌的角色使用一张【杀】。",

  ["os__beini_own"] = "你摸两张牌，其视为对你使用【杀】",
  ["os__beini_other"] = "其摸两张牌，你视为对其使用【杀】",

  ["$os__beini1"] = "今日污无用清名，明朝自得新圣褒嘉。",
  ["$os__beini2"] = "吾佐奉朝日暖旭，又何惮落月残辉？",
}

osBeini:addEffect("active", {
  can_use = function(self, player)
    return player:usedSkillTimes(osBeini.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select.hp >= player.hp
  end,
  target_num = 1,
  interaction = UI.ComboBox { choices = { "os__beini_own", "os__beini_other" } },
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osBeini.name
    local player = effect.from
    local target = effect.tos[1]
    local drawer = self.interaction.data == "os__beini_own" and player or target
    local slasher = self.interaction.data == "os__beini_other" and player or target
    drawer:drawCards(2, skillName)
    if slasher:isAlive() and drawer:isAlive() then
      room:useVirtualCard("slash", nil, slasher, { drawer }, skillName, true)
    end
  end,
})

return osBeini
