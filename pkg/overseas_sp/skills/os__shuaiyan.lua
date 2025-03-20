local os__shuaiyan = fk.CreateSkill {
  name = "os__shuaiyan"
}

Fk:loadTranslationTable{
  ['os__shuaiyan'] = '率言',
  ['#os__shuaiyan-ask'] = '率言：你可展示所有手牌，选择一名其他角色，令其交给你一张牌',
  ['#os__shuaiyan-card'] = '率言：交给 %dest 一张牌',
  [':os__shuaiyan'] = '弃牌阶段开始时，若你的手牌数大于1，你可展示所有手牌，令一名其他角色交给你一张牌。',
  ['$os__shuaiyan1'] = '并魏之日，想来便是两国争战之时。',
  ['$os__shuaiyan2'] = '在下所言，至诚至率。',
}

os__shuaiyan:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and
      player.phase == Player.Discard and player:getHandcardNum() > 1 and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end),
      Util.IdMapper
    )
    local target = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__shuaiyan-ask",
      skill_name = skill.name,
      cancelable = true,
    })
    if #target > 0 then
      event:setCostData(skill, {tos = target})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:showCards(player:getCardIds(Player.Hand))
    local data = event:getCostData(skill)
    if data then
      local target = room:getPlayerById(data.tos[1])
      if not target:isNude() then
        local c = room:askToChooseCards(target, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skill.name,
          prompt = "#os__shuaiyan-card::" .. player.id,
        })
        if #c > 0 then
          room:moveCardTo(c[1], Player.Hand, player, fk.ReasonGive, skill.name, nil, false)
        end
      end
    end
  end,
})

return os__shuaiyan
