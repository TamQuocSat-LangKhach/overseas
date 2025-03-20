local os__chue = fk.CreateSkill {
  name = "os__chue"
}

Fk:loadTranslationTable{
  ['os__chue'] = '除恶',
  ['@os__bravery'] = '勇',
  ['#os__chue-loseHp'] = '除恶：你可失去1点体力，然后此【杀】额外指定至多你的体力值个目标',
  ['#os__chue-use'] = '除恶：你可弃%arg枚“勇”，视为使用一张伤害值基数+1且额外选择%arg个目标的【杀】',
  ['#os__chue-choose'] = '除恶：为此%arg额外指定至多%arg2个目标',
  ['#os__chue-slash'] = '除恶：视为使用一张伤害值基数+1的【杀】，目标至多%arg个',
  [':os__chue'] = '①当你使用【杀】指定唯一目标时，若存在能成为此【杀】目标的一名角色，你可失去1点体力，额外指定至多X个目标。②当你受到伤害或失去体力后，你获得1枚“勇”。③每个回合结束时，你可弃X枚“勇”，视为使用一张【杀】，此【杀】的伤害值基数+1且额外选择X个目标。（X为你的体力值）',
  ['$os__chue1'] = '关某此生，誓斩天下恶徒！',
  ['$os__chue2'] = '政法不行，羽当替天行之！'
}

os__chue:addEffect(fk.TargetSpecifying, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__chue.name) then return false end
    if target ~= player then return false end
    local data = self.data
    return data.card.trueName == "slash" and player.hp > 0 and #AimGroup:getAllTargets(data.tos) == 1 and
      #player.room:getUseExtraTargets(data, true, true) > 0
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, { skill_name = os__chue.name, prompt = "#os__chue-loseHp" })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:loseHp(player, 1, os__chue.name)
    if player.dead then return end
    local availableTargets = room:getUseExtraTargets(self.data, true, true)
    local num = player.hp
    if #availableTargets > 0 and num > 0 then
      local targets = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = num,
        prompt = "#os__chue-choose:::" .. self.data.card:toLogString() .. ":" .. num,
        skill_name = os__chue.name
      })
      if #targets > 0 then
        table.forEach(targets, function(pid) AimGroup:addTargets(room, self.data, pid) end)
      end
    end
  end,
})

os__chue:addEffect(fk.Damaged, {
  on_use = function(self, event, target, player)
    local room = player.room
    room:addPlayerMark(player, "@os__bravery")
  end,
})

os__chue:addEffect(fk.HpLost, {
  on_use = function(self, event, target, player)
    local room = player.room
    room:addPlayerMark(player, "@os__bravery")
  end,
})

os__chue:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__chue.name) then return false end
    return player:getMark("@os__bravery") >= player.hp and player:canUse(Fk:cloneCard("slash"), { bypass_times = true, bypass_distances = true })
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, { skill_name = os__chue.name, prompt = "#os__chue-use:::" .. player.hp })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:removePlayerMark(player, "@os__bravery", player.hp)
    local card = Fk:cloneCard("slash")
    card.skillName = os__chue.name
    local availableTargets = table.map(table.filter(room:getOtherPlayers(player, false), function(p) return player:canUseTo(card, p, { bypass_times = true, bypass_distances = true }) end), Util.IdMapper)
    local num = card.skill:getMaxTargetNum(player, card) + player.hp
    if #availableTargets > 0 and num > 0 then
      local targets = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = num,
        prompt = "#os__chue-slash:::" .. num,
        skill_name = os__chue.name,
        cancelable = false
      })
      local use = { ---@class CardUseStruct
        from = player.id,
        tos = table.map(targets, function(p) return {p} end),
        card = card,
        extra_use = true,
      }
      use.additional_damage = (use.additional_damage or 0) + 1
      room:useCard(use)
    end
  end,
})

return os__chue
