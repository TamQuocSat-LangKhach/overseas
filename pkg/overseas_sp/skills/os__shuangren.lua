local os__shuangren = fk.CreateSkill {
  name = "os__shuangren",
}

Fk:loadTranslationTable{
  ['os__shuangren'] = '双刃',
  ['#os__shuangren_end'] = '你可弃置一张牌发动“双刃”',
  ['#os__shuangren-ask'] = '双刃：你可与一名角色拼点',
  ['#os__shuangren_slash-ask'] = '双刃：你可视为对至 %src 距离不大于1的至多两名角色依次使用一张【杀】',
  ['os__shuangren_counter'] = '双刃：你可视为对其使用一张【杀】',
  ['#os__shuangren_counter-ask'] = '双刃：你可视为对 %src 使用一张【杀】',
  [':os__shuangren'] = '出牌阶段开始时，你可与一名角色拼点。若你赢，可视为对至其距离不大于1的至多两名角色依次使用一张【杀】；若你没赢，其可视为对你使用一张【杀】。出牌阶段结束时，若你本回合未发动过〖双刃〗且未使用【杀】造成过伤害，则你可弃置一张牌发动〖双刃〗。',
  ['$os__shuangren1'] = '仲国大将纪灵在此！',
  ['$os__shuangren2'] = '吃我一记三尖两刃刀！',
}

os__shuangren:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__shuangren.name) and player.phase == Player.Play and not player:isKongcheng() and table.find(player.room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p)
    end) and (event == fk.EventPhaseStart or (player:getMark("_os__shuangren_invalid-turn") == 0 and player:usedSkillTimes(os__shuangren.name) == 0))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      local cids = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = os__shuangren.name,
        cancelable = true,
      }, "#os__shuangren_end")
      if #cids == 0 then return false end
    end
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end
    local target = room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 1,
      skill_name = os__shuangren.name,
      prompt = "#os__shuangren-ask",
    })
    if #target > 0 then
      event:setCostData(self, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targetPlayer = room:getPlayerById(event:getCostData(self))
    local pindian = player:pindian({targetPlayer}, os__shuangren.name)
    if pindian.results[targetPlayer.id].winner == player then
      local slash = Fk:cloneCard("slash")
      if player:prohibitUse(slash) then return false end
      local availableTargets = table.map(
        table.filter(room:getOtherPlayers(player, false), function(p)
          return p:distanceTo(targetPlayer) <= 1 and not player:isProhibited(p, slash)
        end),
        Util.IdMapper
      )
      if #availableTargets == 0 then return false end
      local victims = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = 2,
        skill_name = os__shuangren.name,
        prompt = "#os__shuangren_slash-ask:" .. targetPlayer.id,
      })
      if #victims > 0 then
        for _, pid in ipairs(victims) do
          if player.dead or room:getPlayerById(pid).dead then return false end
          room:useVirtualCard("slash", nil, player, {room:getPlayerById(pid)}, os__shuangren.name, true)
        end
      end
    else
      if room:askToChoice(targetPlayer, {
        choices = {"os__shuangren_counter", "Cancel"},
        skill_name = os__shuangren.name,
        prompt = "#os__shuangren_counter-ask:" .. player.id,
      }) ~= "Cancel" then
        room:useVirtualCard("slash", nil, targetPlayer, {player}, os__shuangren.name, true)
      end
    end
  end,
})

os__shuangren:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player.phase == Player.Play and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__shuangren_invalid-turn")
  end,
})

return os__shuangren
