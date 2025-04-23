local osShuangren = fk.CreateSkill {
  name = "os__shuangren",
}

Fk:loadTranslationTable{
  ["os__shuangren"] = "双刃",
  [":os__shuangren"] = "出牌阶段开始时，你可与一名角色拼点。若你赢，可视为对至其距离不大于1的至多两名角色依次使用一张【杀】；" ..
  "若你没赢，其可视为对你使用一张【杀】。出牌阶段结束时，若你本回合未发动过〖双刃〗且未使用【杀】造成过伤害，则你可弃置一张牌发动〖双刃〗。",

  ["#os__shuangren_end"] = "双刃：你可弃置一张牌并与一名角色拼点",
  ["#os__shuangren-ask"] = "双刃：你可与一名角色拼点",
  ["#os__shuangren_slash-ask"] = "双刃：你可视为对至 %src 距离不大于1的至多两名角色依次使用一张【杀】",
  ["os__shuangren_counter"] = "双刃：你可视为对其使用一张【杀】",
  ["#os__shuangren_counter-ask"] = "双刃：你可视为对 %src 使用一张【杀】",

  ["$os__shuangren1"] = "仲国大将纪灵在此！",
  ["$os__shuangren2"] = "吃我一记三尖两刃刀！",
}

osShuangren:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osShuangren.name) and
      player.phase == Player.Play and
      not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p)
    end)
    if #availableTargets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        skill_name = osShuangren.name,
        prompt = "#os__shuangren-ask",
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osShuangren.name
    local room = player.room
    local targetPlayer = event:getCostData(self)
    local pindian = player:pindian({ targetPlayer }, skillName)
    if pindian.results[targetPlayer].winner == player then
      local slash = Fk:cloneCard("slash")
      if player:prohibitUse(slash) then return false end
      local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p)
        return p:distanceTo(targetPlayer) <= 1 and not player:isProhibited(p, slash)
      end)
      if #availableTargets == 0 then return false end
      local victims = room:askToChoosePlayers(
        player,
        {
          targets = availableTargets,
          min_num = 1,
          max_num = 2,
          skill_name = skillName,
          prompt = "#os__shuangren_slash-ask:" .. targetPlayer.id,
        }
      )
      if #victims > 0 then
        room:sortByAction(victims)
        for _, p in ipairs(victims) do
          if not (player:isAlive() and p:isAlive()) then return false end
          room:useVirtualCard("slash", nil, player, { p }, skillName, true)
        end
      end
    else
      if
        room:askToChoice(
          targetPlayer,
          {
            choices = { "os__shuangren_counter", "Cancel" },
            skill_name = skillName,
            prompt = "#os__shuangren_counter-ask:" .. player.id,
          }
        ) ~= "Cancel"
      then
        room:useVirtualCard("slash", nil, targetPlayer, { player }, skillName, true)
      end
    end
  end,
})

osShuangren:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osShuangren.name) and
      player.phase == Player.Play and
      not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end) and
      player:usedSkillTimes(osShuangren.name) == 0 and
      #player.room.logic:getActualDamageEvents(
        1,
        function(e)
          local damage = e.data
          return damage.from == player and damage.card ~= nil and damage.card.trueName == "slash"
        end,
        Player.HistoryTurn
      ) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p)
    end)
    if #availableTargets == 0 then
      return false
    end

    local tos, cids = room:askToChooseCardsAndPlayers(
      player,
      {
        pattern = ".",
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        min_card_num = 1,
        max_card_num = 1,
        skill_name = osShuangren.name,
        prompt = "#os__shuangren_end",
        will_throw = true,
      }
    )
    if #tos > 0 then
      event:setCostData(self, { tos[1], cids })
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osShuangren.name
    local room = player.room
    room:throwCard(event:getCostData(self)[2], skillName, player, player)

    local targetPlayer = event:getCostData(self)[1]
    local pindian = player:pindian({ targetPlayer }, skillName)
    if pindian.results[targetPlayer].winner == player then
      local slash = Fk:cloneCard("slash")
      if player:prohibitUse(slash) then return false end
      local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p)
        return p:distanceTo(targetPlayer) <= 1 and not player:isProhibited(p, slash)
      end)
      if #availableTargets == 0 then return false end
      local victims = room:askToChoosePlayers(
        player,
        {
          targets = availableTargets,
          min_num = 1,
          max_num = 2,
          skill_name = skillName,
          prompt = "#os__shuangren_slash-ask:" .. targetPlayer.id,
        }
      )
      if #victims > 0 then
        room:sortByAction(victims)
        for _, p in ipairs(victims) do
          if not (player:isAlive() and p:isAlive()) then return false end
          room:useVirtualCard("slash", nil, player, { p }, skillName, true)
        end
      end
    else
      if
        room:askToChoice(
          targetPlayer,
          {
            choices = { "os__shuangren_counter", "Cancel" },
            skill_name = skillName,
            prompt = "#os__shuangren_counter-ask:" .. player.id,
          }
        ) ~= "Cancel"
      then
        room:useVirtualCard("slash", nil, targetPlayer, { player }, skillName, true)
      end
    end
  end,
})

return osShuangren
