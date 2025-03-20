local os__sidai = fk.CreateSkill {
  name = "os__sidai"
}

Fk:loadTranslationTable{
  ['os__sidai'] = '伺怠',
  ['#os__sidai_buff'] = '伺怠',
  ['#os__sidai_nojink'] = '伺怠：弃置一张基本牌，否则不能响应此【杀】',
  [':os__sidai'] = '限定技，出牌阶段，你可将所有基本牌当【杀】使用（无次数和距离限制、不计入使用次数）。若这些牌中有：【酒】，此【杀】造成伤害时，伤害翻倍；【桃】，此【杀】造成伤害后，受到伤害角色减1点体力上限；【闪】，此【杀】的目标需弃置一张基本牌，否则不能响应。',
  ['$os__sidai1'] = '敌军疲乏，正是战机，随我杀！',
  ['$os__sidai2'] = '敌军无备，随我冲锋！'
}

os__sidai:addEffect('viewas', {
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("slash")
    c:addSubcards(table.filter(player.player_cards[Player.Hand], function(cid)
      return Fk:getCardById(cid).type == Card.TypeBasic
    end))
    c.skillName = os__sidai.name
    return c
  end,
  before_use = function(self, player, use)
    local included_basic_cards = {}
    for _, id in ipairs(use.card.subcards) do
      table.insertIfNeed(included_basic_cards, Fk:getCardById(id).name)
    end
    use.extraUse = true
    use.extra_data = use.extra_data or {}
    use.extra_data.os__sidaiBuff = included_basic_cards
    use.card.extra_data = use.card.extra_data or {} --闪用的是这里……
    use.card.extra_data.os__sidaiBuff = included_basic_cards
  end,
  enabled_at_play = function(self, player) --权宜
    return player:usedSkillTimes(os__sidai.name, Player.HistoryGame) == 0 and not table.every(player.player_cards[Player.Hand], function(cid)
      return Fk:getCardById(cid).type ~= Card.TypeBasic
    end)
  end,
  enabled_at_response = Util.FalseFunc,
})

os__sidai:addEffect('targetmod', {
  bypass_times = function (self, player, skill, scope, card, to)
    return (player:hasSkill(os__sidai) and card and table.contains(card.skillNames, os__sidai.name))
  end,
  bypass_distances = function (self, player, skill, card, to)
    return (player:hasSkill(os__sidai) and card and table.contains(card.skillNames, os__sidai.name))
  end
})

os__sidai:addEffect(fk.DamageCaused + fk.Damage + fk.TargetConfirmed, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    if target ~= player or not data.card or not table.contains(data.card.skillNames, os__sidai.name) then return false end
    if event == fk.TargetConfirmed then
      return table.contains((data.card.extra_data or {}).os__sidaiBuff, "jink")
    else
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      local os__sidaiBuff = parentUseData and (parentUseData.data[1].extra_data or {}).os__sidaiBuff or {}
      if event == fk.DamageCaused then
        return table.contains(os__sidaiBuff, "analeptic")
      else
        return table.contains(os__sidaiBuff, "peach") and not data.to.dead
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage * 2
    elseif event == fk.Damage then
      player.room:changeMaxHp(data.to, -1)
    elseif #player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = os__sidai.name,
        cancelable = true,
        pattern = ".|.|.|.|.|basic",
        prompt = "#os__sidai_nojink"
      }) == 0 then
      data.disresponsive = true
    end
  end,
})

return os__sidai
