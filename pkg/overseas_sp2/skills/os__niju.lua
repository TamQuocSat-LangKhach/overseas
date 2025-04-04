local os__niju = fk.CreateSkill {
  name = "os__niju$"
}

Fk:loadTranslationTable{
  ['os__niju_plus'] = '%dest拼点牌点数+%arg',
  ['os__niju_minus'] = '%dest拼点牌点数-%arg',
}

os__niju:addEffect(fk.PindianCardsDisplayed, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(skill.name) then return false end
    return (player == data.from or data.results[player.id]) and table.find(player.room.alive_players, function(p) return p ~= player and p.kingdom == "qun" end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num = #table.filter(room.alive_players, function(p) return p ~= player and p.kingdom == "qun" end)
    local choices = {"os__niju_plus::" .. data.from.id .. ":" .. num, "os__niju_minus::" .. data.from.id .. ":" .. num}
    for p, _ in pairs(data.results) do
      table.insert(choices, "os__niju_plus::" .. p .. ":" .. num)
      table.insert(choices, "os__niju_minus::" .. p .. ":" .. num)
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = skill.name
    })
    if choice ~= "Cancel" then
      event:setCostData(skill, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = event:getCostData(skill):split(":")
    local num = tonumber(choice[4])
    if choice[1] == "os__niju_minus" then num = - num end
    local target = tonumber(choice[3])
    player.room:changePindianNumber(data, player.room:getPlayerById(target), num, skill.name)
    local from = data.fromCard.number
    for _, r in pairs(data.results) do
      if r.toCard.number ~= from then
        return false
      end
    end
    player:drawCards(num, skill.name)
  end,
})

return os__niju
