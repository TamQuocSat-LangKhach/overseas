local os__fenming = fk.CreateSkill {
  name = "os__fenming"
}

Fk:loadTranslationTable{
  ['os__fenming'] = '奋命',
  ['#os__fenming-ask'] = '你可对一名角色发动〖奋命〗',
  ['os__fenming_chained'] = '其进入连环状态',
  ['beishui_os__fenming'] = '背水：你进入连环状态',
  ['os__fenming_discard'] = '你弃置其牌',
  [':os__fenming'] = '准备阶段开始时，你可选择一名角色并选择一项：1.你弃置其一张牌；2. 其进入连环状态；背水：你进入连环状态。',
  ['$os__fenming1'] = '东吴男儿，岂是贪生怕死之辈。',
  ['$os__fenming2'] = '不惜性命，也要保主公周全。',
}

os__fenming:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(os__fenming.name) and
      player.phase == Player.Start and not table.every(player.room.alive_players, function(p)
        return (p:isNude() and p.chained)
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local target = room:askToChoosePlayers(player, {
      targets = table.map(room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__fenming-ask",
      skill_name = os__fenming.name,
      cancelable = true
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
    local choices = {"os__fenming_chained", "beishui_os__fenming"}
    if not target:isNude() then table.insert(choices, 1, "os__fenming_discard") end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__fenming.name
    })

    if choice == "beishui_os__fenming" then
      if not player.chained then player:setChainState(true) end
    end
    if choice ~= "os__fenming_chained" and not target:isNude() then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "he",
        skill_name = os__fenming.name
      })
      room:throwCard(card, os__fenming.name, target, player)
    end
    if choice ~= "os__fenming_discard" and not target.chained then
      target:setChainState(true)
    end
  end,
})

return os__fenming
