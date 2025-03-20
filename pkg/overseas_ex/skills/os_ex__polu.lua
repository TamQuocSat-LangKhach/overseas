local os_ex__polu = fk.CreateSkill {
  name = "os_ex__polu$"
}

Fk:loadTranslationTable{
  ['#os_ex__polu'] = '破虏：你可选择任意名角色，令其各摸 %arg 张牌',
  ['@os_ex__polu'] = '破虏',
}

os_ex__polu:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(os_ex__polu.name) and ((target.damage and target.damage.from and target.damage.from.kingdom == "wu") or target.player.kingdom == "wu")
  end,
  on_trigger = function(self, event, target, player)
    self.cancel_cost = false
    if target.player.kingdom == "wu" then
      self:doCost(event, target, player)
    end
    if self.cancel_cost then return false end
    if target.damage and target.damage.from and target.damage.from.kingdom == "wu" then
      self:doCost(event, target, player)
    end
  end,
  on_cost = function(self, event, target, player)
    local targets = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 99,
      prompt = "#os_ex__polu:::" .. player:usedSkillTimes(os_ex__polu.name, Player.HistoryGame) + 1,
      skill_name = os_ex__polu.name,
      cancelable = true
    })
    if #targets > 0 then
      event:setCostData(self, targets)
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player)
    local targets = event:getCostData(self)
    local room = player.room
    room:sortPlayersByAction(targets)
    room:addPlayerMark(player, "@os_ex__polu")
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        p:drawCards(player:usedSkillTimes(os_ex__polu.name, Player.HistoryGame))
      end
    end
  end,
})

return os_ex__polu
