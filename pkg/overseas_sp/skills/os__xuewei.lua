local os__xuewei = fk.CreateSkill {
  name = "os__xuewei"
}

Fk:loadTranslationTable{
  ['os__xuewei'] = '血卫',
  ['#os__xuewei-ask'] = '你可选择一名除 %dest 以外的其他角色，发动“血卫”',
  ['os__xuewei_defence'] = '直到本回合结束，你不能对 %dest 使用【杀】且手牌上限-2',
  ['os__xuewei_duel'] = '视为 %src 对你使用一张【决斗】',
  ['#os__xuewei_defence'] = '%from 由于“%arg”，不能对 %to 使用【杀】且手牌上限-2',
  [':os__xuewei'] = '每轮限一次，其他角色A的出牌阶段开始时，你可选择另一名其他角色B并令A选择一项：1. 直到本回合结束，其不能对B使用【杀】且手牌上限-2；2. 视为你对其使用一张【决斗】。',
  ['$os__xuewei1'] = '吾主之尊，岂容尔等贼寇近前？',
  ['$os__xuewei2'] = '血佑忠魂，身卫英主。',
}

os__xuewei:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player)
    return target ~= player and player:hasSkill(os__xuewei.name) and target.phase == Player.Play and player:usedSkillTimes(os__xuewei.name, Player.HistoryRound) < 1 and #player.room.alive_players > 2
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local other_players = table.filter(room:getOtherPlayers(target), function(p)
      return p ~= player
    end)

    local to = room:askToChoosePlayers(player, {
      targets = other_players,
      min_num = 1,
      max_num = 1,
      prompt = "#os__xuewei-ask::" .. target.id,
      skill_name = os__xuewei.name,
      cancelable = true
    })

    if #to > 0 then
      event:setCostData(skill, to[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    local all_choices = {"os__xuewei_defence::" .. to.id, "os__xuewei_duel:" .. player.id}
    local choices = table.clone(all_choices)
    local duel = Fk:cloneCard("duel")
    duel.skillName = os__xuewei.name
    if player:prohibitUse(duel) or player:isProhibited(target, duel) then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = os__xuewei.name,
      all_choices = all_choices
    })

    if choice:startsWith("os__xuewei_defence") then
      room:addPlayerMark(target, "_os__xuewei_defence_from-turn", 1)
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 2)
      room:addPlayerMark(to, "_os__xuewei_defence_to-turn", 1)
      room:sendLog{
        type = "#os__xuewei_defence",
        from = target.id,
        to = {to.id},
        arg = os__xuewei.name
      }
    else
      local new_use = {} ---@type CardUseStruct
      new_use.from = player.id
      new_use.tos = {{target.id}}
      new_use.card = duel
      room:useCard(new_use)
    end
  end,
})

local os__xuewei_prohibit = fk.CreateSkill {
  name = "#os__xuewei_prohibit"
}

os__xuewei_prohibit:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    if from:getMark("_os__xuewei_defence_from-turn") > 0 and to:getMark("_os__xuewei_defence_to-turn") > 0 then
      return card.trueName == "slash"
    end
  end,
})

return os__xuewei
