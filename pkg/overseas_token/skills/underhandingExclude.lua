local underhandingExclude = fk.CreateSkill {
  name = "underhanding_exclude",
}

Fk:loadTranslationTable {
  ['underhanding'] = '瞒天过海',
}

underhandingExclude:addEffect('maxcards', {
  global = true,
  exclude_from = function(self, player, card)
    return card and card.name == underhandingExclude.name
  end,
})

return underhandingExclude
