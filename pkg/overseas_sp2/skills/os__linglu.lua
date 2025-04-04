local os__linglu = fk.CreateSkill {
  name = "os__linglu"
}

Fk:loadTranslationTable{
  ['os__linglu'] = '令戮',
  ['#os__linglu-ask'] = '令戮：你可强令一名其他角色在其下回合结束前造成2点伤害',
  ['os__linglu_twice'] = '令其〖令戮〗的失败结算进行两次',
  ['#os__linglu_twice-ask'] = '令戮：你可令 %src 〖令戮〗的失败结算进行两次',
  ['@os__linglu_twice'] = '令戮2',
  ['@os__linglu'] = '令戮',
  [':os__linglu'] = '出牌阶段开始时，你可强令一名其他角色在其下回合结束前造成2点伤害。成功：其摸两张牌；失败：其失去1点体力。<br/><font color=>#"<b>强令</b>"<br/>向一名角色颁布一项任务，在任务结束时点执行奖惩。',
}

os__linglu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__linglu.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local target = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__linglu-ask",
      skill_name = os__linglu.name
    })
    if #target > 0 then
      event:setCostData(self, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local mark_name = player:getMark("_os__linglu_jianshuo") == event:getCostData(self) and room:askToChoice(player, {
      choices = {"os__linglu_twice", "Cancel"},
      skill_name = os__linglu.name,
      prompt = "#os__linglu_twice-ask:" .. event:getCostData(self)
    }) ~= "Cancel" and "@os__linglu_twice" or "@os__linglu"
    local target = room:getPlayerById(event:getCostData(self))
    local mark = target:getTableMark(mark_name)
    table.insert(mark, player.general)
    table.insert(mark, 0)
    room:setPlayerMark(target, mark_name, mark)
    mark_name = string.sub(mark_name, 2)
    room:addTableMark(player, mark_name, player.id)
  end
})

os__linglu:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player)
    return target == player and (player:getMark("@os__linglu") ~= 0 or player:getMark("@os__linglu_twice") ~= 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local mark_names = {"@os__linglu", "@os__linglu_twice"}
    local room = player.room
    for _, mark_name in ipairs(mark_names) do
      local mark = player:getTableMark(mark_name)
      for i = 2, #mark, 2 do
        mark[i] = mark[i] + data.damage
      end
      room:setPlayerMark(player, mark_name, mark)
    end
  end
})

os__linglu:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player)
    return target == player and (player:getMark("@os__linglu") ~= 0 or player:getMark("@os__linglu_twice") ~= 0)
  end,
  on_refresh = function(self, event, target, player)
    local mark_names = {"@os__linglu", "@os__linglu_twice"}
    local room = player.room
    for _, mark_name in ipairs(mark_names) do
      if player.dead then break end
      local mark = player:getTableMark(mark_name)
      for i = 2, #mark, 2 do
        if player.dead then break end
        room:doIndicate(player:getMark(string.sub(mark_name, 2))[i/2], {player.id})
        if mark[i] < 2 then
          room:loseHp(player, 1, os__linglu.name)
          if mark_name == "@os__linglu_twice" then room:loseHp(player, 1, os__linglu.name) end
        else
          player:drawCards(2, os__linglu.name)
        end
      end
      room:setPlayerMark(player, mark_name, 0)
      room:setPlayerMark(player, string.sub(mark_name, 2), 0)
    end
  end
})

return os__linglu
