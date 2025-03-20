local os_ex__yuzhang = fk.CreateSkill {
  name = "os_ex__yuzhang"
}

Fk:loadTranslationTable{
  ['os_ex__yuzhang'] = '御嶂',
  ['@os_ex__strategy'] = '策',
  ['#os_ex__yuzhang'] = '御嶂：你可弃1枚“策”，跳过 %arg',
  ['os_ex__yuzhang_disable'] = '令%dest本回合不能再使用或打出手牌',
  ['os_ex__yuzhang_discard'] = '%dest弃置两张牌',
  ['#os_ex__yuzhang-ask'] = '御嶂：你可弃1枚“策”，选择一项，令 %dest 执行',
  ['@os_ex__yuzhang_pro-turn'] = '御嶂 禁止出牌',
  [':os_ex__yuzhang'] = '①你可弃1枚“策”，跳过一个阶段。②当你受到伤害后，你可弃1枚“策”并选择一项，令伤害来源执行：1.本回合不能使用或打出手牌；2.弃置两张牌（不足则全弃）。',
  ['$os_ex__yuzhang1'] = '吾已料敌布防，蜀军休想进犯！',
  ['$os_ex__yuzhang2'] = '诸君依策行事，定保魏境无虞！',
}

os_ex__yuzhang:addEffect(fk.EventPhaseChanging, {
  anim_type = "masochism",
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os_ex__yuzhang.name) and
      data.to >= Player.Start and data.to <= Player.Finish and player:getMark("@os_ex__strategy") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askToSkillInvoke(player, { skill_name = os_ex__yuzhang.name, prompt = "#os_ex__yuzhang:::" .. Util.PhaseStrMapper(data.to) })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@os_ex__strategy")
    player:broadcastSkillInvoke(os_ex__yuzhang.name)
    room:notifySkillInvoked(player, os_ex__yuzhang.name, "defensive")
    return true
  end,
})

os_ex__yuzhang:addEffect(fk.Damaged, {
  anim_type = "masochism",
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os_ex__yuzhang.name) and player:getMark("@os_ex__strategy") > 0 and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local pid = data.from.id
    local choice = room:askToChoice(player, {
      choices = {"os_ex__yuzhang_disable::" .. pid, "os_ex__yuzhang_discard::" .. pid, "Cancel"},
      skill_name = os_ex__yuzhang.name,
      prompt = "#os_ex__yuzhang-ask::" .. pid
    })
    if choice ~= "Cancel" then
      event:setCostData(skill, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@os_ex__strategy")
    player:broadcastSkillInvoke(os_ex__yuzhang.name)
    room:notifySkillInvoked(player, os_ex__yuzhang.name)
    local choice = event:getCostData(skill)
    local tar = data.from
    if choice:startsWith("os_ex__yuzhang_discard") then
      room:askToDiscard(tar, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = os_ex__yuzhang.name,
        cancelable = false,
      })
    else
      room:addPlayerMark(tar, "@os_ex__yuzhang_pro-turn", 1)
    end
  end,
})

local os_ex__yuzhang_prohibit = fk.CreateSkill {
  name = "#os_ex__yuzhang_prohibit"
}

os_ex__yuzhang_prohibit:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("@os_ex__yuzhang_pro-turn") > 0 and card and #card.skillNames == 0 then
      local subcards = Card:getIdList(card)
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getHandlyIds(true), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@os_ex__yuzhang_pro-turn") > 0 and card and #card.skillNames == 0 then
      local subcards = Card:getIdList(card)
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getHandlyIds(true), id)
      end)
    end
  end,
})

os_ex__yuzhang:addRelatedSkill(os_ex__yuzhang_prohibit)

return os_ex__yuzhang
