local os__yuyan = fk.CreateSkill {
  name = "os__yuyan"
}

Fk:loadTranslationTable{
  ['os__yuyan'] = '御严',
  ['#os__yuyan-card1'] = '御严：交给 %src 一张非基本牌，否则取消此目标',
  ['#os__yuyan-card2'] = '御严：交给 %src 一张点数大于 %arg 的牌，否则取消此目标',
  [':os__yuyan'] = '锁定技，当你成为体力值大于你的角色【杀】的目标时，其须交给你一张点数大于此【杀】点数的牌（若此【杀】无点数则改为非基本牌），否则取消此目标。',
  ['$os__yuyan1'] = '正直敢言，不惧圣怒。',
  ['$os__yuyan2'] = '威武不能屈，方为大丈夫。',
}

os__yuyan:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__yuyan) and data.card.trueName == "slash" and player.room:getPlayerById(data.from).hp > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pattern
    local prompt
    if data.card.number < 1 then 
      pattern = ".|.|.|.|.|^basic"
      prompt = "#os__yuyan-card1:" .. player.id
    else
      pattern = ".|" .. data.card.number + 1 .. "~K"
      prompt = "#os__yuyan-card2:" .. player.id .. "::" .. data.card.number
    end
    local c = room:askToCards(room:getPlayerById(data.from), {
      min_num = 1,
      max_num = 1,
      pattern = pattern,
      skill_name = os__yuyan.name,
      cancelable = true,
      prompt = prompt,
    })
    if #c > 0 then
      room:moveCardTo(c[1], Player.Hand, player, fk.ReasonGive, os__yuyan.name, nil, false)
    else
      AimGroup:cancelTarget(data, data.to)
    end
  end,
})

return os__yuyan
