local os__saotao = fk.CreateSkill {
  name = "os__saotao"
}

Fk:loadTranslationTable{
  ['os__saotao'] = '扫讨',
  [':os__saotao'] = '锁定技，你使用的【杀】和普通锦囊牌不能被响应。',
}

os__saotao:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__saotao.name) and 
      (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
})

return os__saotao
