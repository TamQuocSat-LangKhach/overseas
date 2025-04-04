local os__jilun = fk.CreateSkill {
  name = "os__jilun"
}

Fk:loadTranslationTable{
  ['os__jilun'] = '机论',
  ['@$os__jichou'] = '急筹',
  ['os__jilun_draw'] = '摸%arg张牌',
  ['@$os__jilun'] = '机论',
  ['os__jilun_use'] = '视为使用一种以“急筹”使用过的牌（每牌名限一次）',
  ['#os__jilun-ask'] = '机论：请选择一项',
  ['os__jilun_vs'] = '机论',
  ['#os__jilun-vs'] = '视为使用一种以“急筹”使用过的牌（每牌名限一次）',
  [':os__jilun'] = '当你受到伤害后，你可选择一项：1. 摸X张牌（X为以“急筹”使用过的锦囊牌数，至少为1至多为5）；2. 视为使用一种以“急筹”使用过的牌（每牌名限一次）。',
  ['$os__jilun1'] = '时移不移，违天之祥也。',
  ['$os__jilun2'] = '民望不因，违人之咎也。',
}

os__jilun:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function(self, event, target, player)
    local num = #player:getTableMark("@$os__jichou")
    local choices = {"os__jilun_draw:::" .. math.min(math.max(num, 1), 5), "Cancel"}
    local os__jilunRecord = player:getTableMark("@$os__jilun")
    for _, name in ipairs(os__jilunRecord) do
      local card = Fk:cloneCard(name)
      if not player:prohibitUse(card) and player:canUse(card) then
        table.insert(choices, 2, "os__jilun_use")
        break
      end
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = os__jilun.name,
      prompt = "#os__jilun-ask"
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choice = event:getCostData(self)
    if choice == "os__jilun_use" then
      local success, dat = room:askToUseViewAsSkill(player, {
        skill_name = "os__jilun_vs",
        prompt = "#os__jilun-vs",
        cancelable = false,
      })
      if success then
        local card = Fk.skills["os__jilun_vs"]:viewAs(dat.cards)
        local use = {
          from = player.id,
          tos = table.map(dat.targets, function(e) return {e} end),
          card = card,
        }
        Fk.skills["os__jilun_vs"]:beforeUse(player, use)
        room:useCard(use)
      end
    else
      local num = type(player:getMark("@$os__jichou")) == "table" and #player:getMark("@$os__jichou") or 0
      player:drawCards(math.min(math.max(num, 1), 5), os__jilun.name)
    end
  end,
})

return os__jilun
