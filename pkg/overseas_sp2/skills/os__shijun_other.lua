local os__shijun_other = fk.CreateSkill {
  name = "os__shijun_other&"
}

Fk:loadTranslationTable{
  ['os__shijun_other&'] = '师君',
  ['os__shijun'] = '师君',
  ['#os__shijun-put'] = '师君：将一张牌置于 %src 的武将牌上',
  [':os__shijun_other&'] = '出牌阶段限一次，若张鲁没有“米”，你可以摸一张牌，然后将一张牌置于其武将牌上，称为“米”。',
}

os__shijun_other:addEffect('active', {
  can_use = function(self, player)
    if player:usedSkillTimes(skill.name, Player.HistoryPhase) < 1 and player.kingdom == "qun" then
      return table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill("os__shijun") and p ~= player and #p:getPile("zhanglu_mi") == 0 end)
    end
    return false
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room.alive_players, function(p) return p:hasSkill("os__shijun") and p ~= player and #p:getPile("zhanglu_mi") == 0 end)
    local target
    if #targets == 1 then
      target = targets[1]
    else
      target = room:getPlayerById(room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = skill.name,
        cancelable = false,
      })[1])
    end
    if not target then return false end
    room:notifySkillInvoked(player, "os__shijun", "support")
    player:broadcastSkillInvoke("os__shijun")
    room:doIndicate(effect.from, { target.id })
    player:drawCards(1, skill.name)
    if not (player:isNude() or player.dead) then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skill.name,
        cancelable = false,
        prompt = "#os__shijun-put:" .. target.id
      })
      target:addToPile("zhanglu_mi", card[1], true, skill.name)
    end
  end,
})

return os__shijun_other
