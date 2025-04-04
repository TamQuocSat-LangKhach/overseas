local os__jilun = fk.CreateSkill {
  name = "os__jilun"
}

Fk:loadTranslationTable{
  ['os__jilun_vs'] = '机论',
  ['@$os__jilun'] = '机论',
}

os__jilun:addEffect('viewas', {
  card_filter = Util.FalseFunc,
  card_num = 0,
  pattern = "nullification",
  interaction = function(self)
    local allCardNames = {}
    local os__jilunRecord = self.player:getTableMark("@$os__jilun")
    for _, name in ipairs(os__jilunRecord) do
      local card = Fk:cloneCard(name)
      card.skillName = os__jilun.name
      if not self.player:prohibitUse(card) and self.player:canUse(card) then
        table.insert(allCardNames, name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  view_as = function(self, player, cards)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = os__jilun.name
    return c
  end,
  before_use = function(self, player, use)
    local os__jilunRecord = player:getTableMark("@$os__jilun")
    table.removeOne(os__jilunRecord, use.card.name)
    player.room:setPlayerMark(player, "@$os__jilun", os__jilunRecord)
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = Util.FalseFunc,
})

return os__jilun
