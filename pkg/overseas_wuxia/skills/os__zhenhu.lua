local os__zhenhu = fk.CreateSkill {
  name = "os__zhenhu"
}

Fk:loadTranslationTable{
  ['os__zhenhu'] = '震虎',
  ['#os__chaofeng-ask'] = '朝凤：你可与至多三名角色共同拼点，赢的角色视为对没赢的角色使用火【杀】',
  [':os__zhenhu'] = '当你使用伤害牌指定第一个目标时，你可摸一张牌并与至多三名其他角色共同拼点：若你赢，此牌对没赢的角色造成伤害+1。若你没赢，你失去1点体力。<br/><font color=>#"<b>共同拼点</b>"<br/>所有角色一起比大小（而非“同时拼点”：发起者和其余角色两两各比大小）。',
  ['$os__zhenhu1'] = '戟出势如虎，百兽尽皆服！',
  ['$os__zhenhu2'] = '横戟冲阵，敌纵为猛虎凶豺，亦不敢前！',
}

os__zhenhu:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(os__zhenhu.name) and data.card.is_damage_card and
      data.firstTarget and table.find(player.room:getOtherPlayers(player, false), function(p) return player:canPindian(p) end)
  end,
  on_use = function(self, event, target, player)
    player:drawCards(1, os__zhenhu.name)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end
    local targets = room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 3,
      prompt = "#os__chaofeng-ask",
      skill_name = os__zhenhu.name,
      cancelable = false,
    })
    if #targets == 0 then return false end
    local pd = U.jointPindian(player, table.map(targets, Util.Id2PlayerMapper), os__zhenhu.name)
    if pd.winner == player then
      data.extra_data = data.extra_data or {}
      data.extra_data.os__zhenhu = targets
    else
      room:loseHp(player, 1, os__zhenhu.name)
    end
  end,
})

os__zhenhu:addEffect(fk.DamageCaused, {
  can_refresh = function(self, event, target, player)
    if target ~= player then return false end
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return parentUseData and type((parentUseData.data[1].extra_data or {}).os__zhenhu) == "table" and table.contains((parentUseData.data[1].extra_data or {}).os__zhenhu, data.to.id)
  end,
  on_refresh = function(self, event, target, player)
    data.damage = data.damage + 1
  end,
})

return os__zhenhu
