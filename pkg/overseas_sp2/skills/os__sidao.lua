local os__sidao = fk.CreateSkill {
  name = "os__sidao"
}

Fk:loadTranslationTable{
  ['os__sidao'] = '司道',
  ['os__sidao_select'] = '司道',
  ['#os__sidao-ask'] = '司道：选择一件法宝并使用之',
  [':os__sidao'] = '①游戏开始时，你选择一件法宝并使用之：【灵宝仙葫】、【太极拂尘】、【冲应神符】。②准备阶段开始时，若你选择过的法宝不在游戏内或在牌堆或弃牌堆中，则你获得并使用之。<br/><font color=>【<b>灵宝仙葫</b>】<font color=>♥</font>A  装备牌·武器 攻击范围：3  锁定技，当你造成大于1点的伤害时或一名角色死亡时，你增加1点体力上限并回复1点体力。<br/>【<b>太极拂尘</b>】<font color=>♥</font>A  装备牌·武器 攻击范围：5  当你使用的【杀】指定目标后，目标角色需弃置一张牌，否则不可响应此【杀】；若其弃置的牌与此【杀】花色相同，你获得之。<br/>【<b>冲应神符</b>】<font color=>♥</font>A  装备牌·防具  锁定技，当你受到一种牌名的牌造成的伤害后，本局游戏同牌名的牌对你造成的伤害-1。</font>',
  ['$os__sidao1'] = '执吾法器，以司正道。',
  ['$os__sidao2'] = '内修道法，外需宝器。',
}

os__sidao:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return true
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, player)
    local room = player.room
    local cards = table.filter(U.prepareDeriveCards(room, sidao_derivecards, "sidao_derivecards"), function (id)
      return room:getCardArea(id) == Card.Void
    end)
    if #cards == 0 then return false end
    room:setPlayerMark(player, "os__sidao_cards", cards)
    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "os__sidao_select",
      prompt = "#os__sidao-ask",
      cancelable = false,
    })
    local cardId = dat and dat.cards[1] or table.random(cards)
    room:setPlayerMark(player, "_os__sidao", cardId)
    room:useCard({ from = player.id, tos = { {player.id} }, card = Fk:getCardById(cardId) })
  end,
})

os__sidao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return player.phase == Player.Start and player:getMark("_os__sidao") ~= 0
      and table.contains({Card.DiscardPile, Card.DrawPile, Card.Void, Card.PlayerSpecial}, player.room:getCardArea(player:getMark("_os__sidao")))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, player)
    local room = player.room
    local cardId = player:getMark("_os__sidao")
    room:obtainCard(player, cardId, true, fk.ReasonPrey)
    if table.contains(player:getCardIds("he"), cardId) and player:canUseTo(Fk:getCardById(cardId), player) then
      room:useCard({ from = player.id, tos = { {player.id} }, card = Fk:getCardById(cardId) })
    end
  end,
})

os__sidao:addEffect(fk.BeforeCardsMove, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local hold_areas = {Card.PlayerEquip, Card.Processing, Card.Void, Card.PlayerHand, Card.PlayerSpecial}
    local card_names = {"celestial_calabash", "horsetail_whisk", "talisman"}
    local mirror_moves = {}
    local ids = {}
    for _, move in ipairs(data) do
      if not table.contains(hold_areas, move.toArea) then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.contains(card_names, Fk:getCardById(id).name) then
            table.insert(mirror_info, info)
            table.insert(ids, id)
          else
            table.insert(move_info, info)
          end
        end
        if #mirror_info > 0 then
          move.moveInfo = move_info
          local mirror_move = table.clone(move)
          mirror_move.to = nil
          mirror_move.toArea = Card.Void
          mirror_move.moveInfo = mirror_info
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{
        type = "#destructDerivedCards",
        card = ids,
      }
    end
    table.insertTable(data, mirror_moves)
  end,
})

return os__sidao
