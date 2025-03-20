local os__chayi = fk.CreateSkill {
  name = "os__chayi"
}

Fk:loadTranslationTable{
  ['os__chayi'] = '察异',
  ['#os__chayi-ask'] = '你可对一名其他角色发动“察异”',
  ['os__chayi_discard'] = '下一次使用牌时弃置一张牌',
  ['os__chayi_show'] = '展示手牌',
  ['#os__chayi-choice'] = '察异：你的下回合结束前，若你的手牌数与此时不同，你执行此时选择的另一项',
  ['@os__chayi_show'] = '察异 展示',
  ['@os__chayi_discard'] = '察异 弃牌',
  ['@@os__chayi_discard'] = '察异 弃牌',
  ['#os__chayi_using'] = '察异',
  ['#os__chayi-discard'] = '察异：你使用了一张牌，须弃置一张牌',
  [':os__chayi'] = '结束阶段开始时，你可令一名其他角色选择一项：1. 展示其手牌；2. 其下一次使用牌时弃置一张牌。其下回合开始后，若其手牌数与你选择其时不同，则其执行另一项。',
  ['$os__chayi1'] = '戮力一心，同讨魏贼。',
}

os__chayi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__chayi.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    target = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__chayi-ask",
      skill_name = os__chayi.name
    })
    if #target > 0 then
      event:setCostData(self, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    target = room:getPlayerById(event:getCostData(self))
    local choices = {"os__chayi_discard"}
    if target:getHandcardNum() > 0 then table.insert(choices, 1, "os__chayi_show") end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = os__chayi.name,
      prompt = "#os__chayi-choice"
    })
    local cids = target:getCardIds(Player.Hand)
    room:addPlayerMark(target, "_os__chayi", 1)
    if choice == "os__chayi_show" then
      target:showCards(cids)
      room:setPlayerMark(target, "@os__chayi_show", tostring(#cids)) --如果为0，所以要用string
    else
      room:setPlayerMark(target, "@os__chayi_discard", tostring(#cids))
      room:setPlayerMark(target, "_os__chayi_discarded", 0)
    end
  end,
  can_refresh = function(self, event, target, player)
    return player == target and player:getMark("_os__chayi") > 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "_os__chayi", 0)
    if player:getMark("@os__chayi_show") ~= 0 then
      if player:getHandcardNum() ~= tonumber(player:getMark("@os__chayi_show")) then
        room:setPlayerMark(player, "@@os__chayi_discard", 1)
        room:setPlayerMark(target, "_os__chayi_discarded", 0)
      end
      room:setPlayerMark(player, "@os__chayi_show", 0)
    end
    if player:getMark("@os__chayi_discard") ~= 0 then
      if player:getHandcardNum() ~= tonumber(player:getMark("@os__chayi_discard")) then
        player:showCards(player:getCardIds(Player.Hand))
      end
      room:setPlayerMark(player, "@@os__chayi_discard", 1)
    end
  end,
})

os__chayi:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("_os__chayi") > 0 and (player:getMark("@os__chayi_discard") ~= 0 or player:getMark("@@os__chayi_discard") > 0) and player:getMark("_os__chayi_discarded") < 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "_os__chayi_discarded", 1)
    local cids = table.clone(player:getCardIds(Player.Hand))
    table.insertTable(cids, player:getCardIds(Player.Equip))
    if table.find(cids, function(id)
      return not player:prohibitDiscard(Fk:getCardById(id))
    end) then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = os__chayi.name,
        cancelable = false,
        prompt = "#os__chayi-discard"
      })
    end
    room:setPlayerMark(player, "@@os__chayi_discard", 0)
  end,
})

return os__chayi
