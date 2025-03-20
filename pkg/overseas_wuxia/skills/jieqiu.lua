local jieqiu = fk.CreateSkill {
  name = "os__jieqiu"
}

Fk:loadTranslationTable{
  ['os__jieqiu'] = '劫囚',
  ['@os__jieqiu'] = '被劫囚',
  ['#os__jieqiu_delay'] = '劫囚',
  ['#os__jieqiu-ask'] = '劫囚：你可执行一个额外回合',
  ['#os__jieqiu-choice'] = '劫囚：恢复 %arg 个装备栏',
  [':os__jieqiu'] = '出牌阶段限一次，你可选择一名所有装备栏均未被废除的其他角色，废除其所有装备栏，然后其摸X张牌（X为废除前其装备区里的牌数）。其弃牌阶段结束时，其恢复等同于此阶段弃置手牌数量的装备栏。其回合结束时，若仍有装备栏被废除，则你可执行一个额外回合（每轮限一次）。',
  ['$os__jieqiu1'] = '元直莫慌，石韬来也！',
  ['$os__jieqiu2'] = '一群鼠辈，焉能挡我等去路！',
}

jieqiu:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jieqiu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #getSealedEquipSlot(Fk:currentRoom():getPlayerById(to_select)) == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local num = #target:getCardIds(Player.Equip)
    room:abortPlayerArea(target, target.equipSlots)
    if not target.dead then
      room:setPlayerMark(target, "@os__jieqiu", player.general)
      room:setPlayerMark(target, "_os__jieqiu", player.id)
      target:drawCards(num, jieqiu.name)
    end
  end,
})

jieqiu:addEffect({fk.EventPhaseEnd, fk.TurnEnd}, {
  anim_type = "control",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target:getMark("_os__jieqiu") == 0 or target.dead then return end
    if event == fk.EventPhaseEnd then
      if target == player and target.phase == Player.Discard then
        local num = 0
        player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          for _, move in ipairs(e.data) do
            if move.from == target.id and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  num = num + 1
                end
              end
            end
          end
          return false
        end, Player.HistoryPhase)
        if num > 0 then
          event:setCostData(self, num)
          return true
        end
      end
    elseif target:getMark("_os__jieqiu") == player.id and not player.dead then
      return player:usedSkillTimes(jieqiu.name, Player.HistoryRound) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local params = {
      skill_name = jieqiu.name,
      prompt = "#os__jieqiu-ask"
    }
    return event == fk.EventPhaseEnd or player.room:askToSkillInvoke(player, params)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      local num = event:getCostData(self)
      local all_choices = getSealedEquipSlot(player)
      if #all_choices > 0 then
        local choices_params = {
          choices = all_choices,
          min_num = num,
          max_num = num,
          skill_name = jieqiu.name,
          prompt = "#os__jieqiu-choice:::" .. num,
          detailed = false
        }
        local choices = room:askToChoices(player, choices_params)
        room:resumePlayerArea(player, choices)
      end
    else
      room:doIndicate(player.id, {target.id})
      room:notifySkillInvoked(player, jieqiu.name, "control")
      player:broadcastSkillInvoke("os__jieqiu")
      player:gainAnExtraTurn()
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return player == target and #getSealedEquipSlot(player) == 0 and player:getMark("_os__jieqiu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__jieqiu", 0)
    room:setPlayerMark(player, "_os__jieqiu", 0)
  end,
})

return jieqiu
